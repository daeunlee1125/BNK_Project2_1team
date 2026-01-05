package kr.co.api.backend.service.async;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class LogProducer {

    private final RedisTemplate<String, Object> redisTemplate;

    // Redis Key (Queue 이름)
    private static final String QUEUE_NAME = "history_queue";

    /**
     * 이력 데이터 비동기 전송 (Producer)
     * - 목적: DB 변경 대기 시간을 없애 API 응답 속도 향상
     * - 방식: Redis List(Queue)에 데이터를 밀어넣고(Push) 즉시 리턴
     */
    public void sendLog(Map<String, Object> logData) {
        try {
            // Redis List의 오른쪽에 데이터를 밀어넣음 (Push)
            redisTemplate.opsForList().rightPush(QUEUE_NAME, logData);

            // 비동기 처리 성공 시각화
            log.info("[비동기 요청] 이력 데이터가 Redis 큐(Queue)에 적재되었습니다.");

        } catch (Exception e) {
            log.error("⚠️ [비동기 적재 실패] Redis 연결 실패. 이력 데이터가 누락되었습니다 : {}", e.getMessage());
        }
    }
}