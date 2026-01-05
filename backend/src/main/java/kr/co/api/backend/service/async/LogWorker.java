package kr.co.api.backend.service.async;

import lombok.extern.slf4j.Slf4j;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.DefaultTransactionDefinition;

import java.util.Map;

@Slf4j
@Component
public class LogWorker {

    private final RedisTemplate<String, Object> redisTemplate;
    private final SqlSessionTemplate slaveSqlSession;
    private final PlatformTransactionManager slaveTransactionManager;

    // 큐 이름 상수 정의
    private static final String QUEUE_NAME = "history_queue";
    private static final String ERROR_QUEUE_NAME = "history_queue:error";

    @Autowired
    public LogWorker(
            RedisTemplate<String, Object> redisTemplate,
            @Qualifier("slaveSqlSessionTemplate") SqlSessionTemplate slaveSqlSession,
            @Qualifier("slaveTransactionManager") PlatformTransactionManager slaveTransactionManager
    ) {
        this.redisTemplate = redisTemplate;
        this.slaveSqlSession = slaveSqlSession;
        this.slaveTransactionManager = slaveTransactionManager;
    }

    /**
     * 0.1초(100ms)마다 Redis 큐를 확인하여 이력 데이터 처리
     * - Master DB 부하 없음 (Slave DB에만 Write)
     */
    @Scheduled(fixedDelay = 100)
    public void processQueue() {
        // 1. Redis 큐(왼쪽)에서 데이터 꺼내기 (Pop)
        Object data = redisTemplate.opsForList().leftPop(QUEUE_NAME);

        if (data != null) {
            TransactionStatus status = null;
            Map<String, Object> map = null;

            try {
                // Slave 트랜잭션 시작
                status = slaveTransactionManager.getTransaction(new DefaultTransactionDefinition());
                map = (Map<String, Object>) data;

                String logType = (String) map.get("log_type");

                // 처리 시작 알림
                log.info("[Async Worker] 큐에서 이력 데이터 수신. (Type: {})", logType);

                if ("EXCHANGE".equals(logType)) {
                    // 환전 이력 저장
                    slaveSqlSession.insert("kr.co.api.backend.mapper.OnlineExchangeMapper.insertOnlineExchange", map);
                    log.info("[환전 이력] Slave DB 적재 중...");

                } else if ("TRANSFER".equals(logType)) {
                    // 이체 이력 저장 (CustTranHist 등)
                    slaveSqlSession.insert("kr.co.api.backend.mapper.OnlineExchangeMapper.insertCustTranHist", map);
                    log.info("[이체 이력] Slave DB 적재 중...");

                } else {
                    log.warn("[Async Worker] 알 수 없는 로그 타입입니다: {}", logType);
                }

                // 커밋
                slaveTransactionManager.commit(status);

                // [핵심 로그] 부하 분산 성공 메시지
                log.info("[부하 분산 처리됨] Master DB를 거치지 않고 Slave DB에 저장 완료. (Master 부하 0%)");

            } catch (Exception e) {
                // 실패 시 롤백 및 에러 큐로 이동 (DLQ 패턴)
                if (status != null) slaveTransactionManager.rollback(status);

                log.error("[처리 실패] DB 저장 중 오류 발생. 에러 큐(Dead Letter Queue)로 이동합니다 : {}", e.getMessage());

                if (map != null) {
                    map.put("error_msg", e.getMessage());
                    redisTemplate.opsForList().rightPush(ERROR_QUEUE_NAME, map);
                } else {
                    redisTemplate.opsForList().rightPush(ERROR_QUEUE_NAME, data);
                }
            }
        }
    }
}