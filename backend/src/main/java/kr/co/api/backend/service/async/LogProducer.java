package kr.co.api.backend.service.async;

import kr.co.api.backend.dto.CustTranHistDTO; // (또는 관련 DTO)
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class LogProducer {

    private final RedisTemplate<String, Object> redisTemplate;

    // 큐 이름 정의
    private static final String QUEUE_NAME = "history_queue";

    public void sendLog(Map<String, Object> logData) {
        // Redis List의 오른쪽에 데이터를 밀어넣음 (Push)
        redisTemplate.opsForList().rightPush(QUEUE_NAME, logData);
    }
}