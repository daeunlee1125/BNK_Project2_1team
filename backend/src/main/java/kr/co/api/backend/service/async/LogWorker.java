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

    @Scheduled(fixedDelay = 1000)
    public void processQueue() {
        Object data = redisTemplate.opsForList().leftPop(QUEUE_NAME);

        if (data != null) {
            TransactionStatus status = null;
            Map<String, Object> map = null;
            try {
                status = slaveTransactionManager.getTransaction(new DefaultTransactionDefinition());
                map = (Map<String, Object>) data;

                // 데이터 타입에 따라 다른 테이블에 저장
                String logType = (String) map.get("log_type");

                if ("EXCHANGE".equals(logType)) {
                    // 1. 환전 내역
                    log.info(">>>> [Async Worker] 환전 내역 저장 시도...");
                    slaveSqlSession.insert("kr.co.api.backend.mapper.OnlineExchangeMapper.insertOnlineExchange", map);

                } else if ("TRANSFER".equals(logType)) {
                    // 2. 이체 내역
                    log.info(">>>> [Async Worker] 이체 내역 저장 시도...");
                    slaveSqlSession.insert("kr.co.api.backend.mapper.OnlineExchangeMapper.insertCustTranHist", map);

                } else {
                    // 3. 알 수 없는 타입 (예외 처리 또는 로깅)
                    log.warn(">>>> [Async Worker] 알 수 없는 로그 타입입니다: {}", logType);
                }

                slaveTransactionManager.commit(status);
                log.info(">>>> [Async Worker] Slave DB 저장 완료!");

            } catch (Exception e) {
                if (status != null) slaveTransactionManager.rollback(status);
                log.error(">>>> [Async Worker] 저장 실패! 에러 큐로 이동: {}", e.getMessage());

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