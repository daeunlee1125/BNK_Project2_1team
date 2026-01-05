package kr.co.api.backend.schedule;

import kr.co.api.backend.config.DbStatusManager;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

@Slf4j
@Component
public class DbHealthChecker {

    private final DataSource masterPingDataSource;
    private final DataSource slavePingDataSource;
    private final DbStatusManager dbStatusManager;

    // 상태 변화 감지를 위한 이전 상태 저장 변수
    private boolean wasMasterAlive = true;
    private boolean wasSlaveAlive = true;

    @Autowired
    public DbHealthChecker(
            @Qualifier("masterPingDataSource") DataSource masterPingDataSource,
            @Qualifier("slavePingDataSource") DataSource slavePingDataSource,
            DbStatusManager dbStatusManager) {
        this.masterPingDataSource = masterPingDataSource;
        this.slavePingDataSource = slavePingDataSource;
        this.dbStatusManager = dbStatusManager;
    }

    // 1초(1000ms)마다 실행되어 DB 생존 여부 확인
    @Scheduled(fixedDelay = 1000)
    public void checkDbHealth() {

        // -------------------------------------------------------
        // 1. Master DB 검사
        // -------------------------------------------------------
        boolean isMasterAlive = checkConnection(masterPingDataSource);

        // 상태가 변경되었을 때만 로그 출력 (UP <-> DOWN)
        if (wasMasterAlive && !isMasterAlive) {
            // Case: Master가 살아있다가 죽음 (장애 발생)
            log.error("[긴급 장애 감지] Master DB 연결이 끊겼습니다! (Connection Refused)");
            log.error("[Failover 가동] 모든 트래픽을 즉시 Slave DB로 전환합니다.");
        }
        else if (!wasMasterAlive && isMasterAlive) {
            // Case: Master가 죽었다가 살아남 (복구)
            log.info("[자동 복구] Master DB 연결이 정상화되었습니다.");
            log.info("[Failback 완료] 메인 트래픽 처리를 Master DB로 복귀시킵니다.");
        }

        // 상태 매니저에 최신 상태 반영
        dbStatusManager.setMasterAlive(isMasterAlive);
        wasMasterAlive = isMasterAlive; // 현재 상태 기억


        // -------------------------------------------------------
        // 2. Slave DB 검사
        // -------------------------------------------------------
        boolean isSlaveAlive = checkConnection(slavePingDataSource);

        if (wasSlaveAlive && !isSlaveAlive) {
            log.warn("[경고] Slave DB 연결 끊김. (Master 단독 운영 체제로 전환)");
        }
        else if (!wasSlaveAlive && isSlaveAlive) {
            log.info("[복구] Slave DB 재연결 성공. (이중화 대기 상태 복귀)");
        }

        dbStatusManager.setSlaveAlive(isSlaveAlive);
        wasSlaveAlive = isSlaveAlive;
    }

    /**
     * DB 연결 테스트 (Ping Query)
     * - 1초 타임아웃 설정으로 빠른 장애 감지
     */
    private boolean checkConnection(DataSource dataSource) {
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            // 1초 안에 응답 없으면 장애로 판단
            stmt.setQueryTimeout(1);
            stmt.executeQuery("SELECT 1 FROM DUAL"); // 가벼운 쿼리 실행

            return true; // 성공
        } catch (Exception e) {
            // 연결 실패 시 예외 발생 -> false 반환
            return false;
        }
    }
}