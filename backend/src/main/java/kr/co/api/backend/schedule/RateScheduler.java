package kr.co.api.backend.schedule;

import kr.co.api.backend.service.RateService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class RateScheduler {

    private final RateService rateService;

    //  테스트용: 오늘 12:17에 1회 실행
    @Scheduled(cron = "0 0 11 * * MON-FRI", zone = "Asia/Seoul")
    public void collectRateTest() {
        rateService.collectTodayRate();
    }
}