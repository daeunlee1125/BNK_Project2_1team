package kr.co.api.backend.schedule; // 패키지명 확인 (scheduler 인지 schedule 인지)

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

    private final DataSource masterPingDataSource; // 이름 변경 (명확하게)
    private final DataSource slavePingDataSource;  // 이름 변경
    private final DbStatusManager dbStatusManager;

    @Autowired
    public DbHealthChecker(
            @Qualifier("masterPingDataSource") DataSource masterPingDataSource, // ★ [수정] 핑 전용 주입
            @Qualifier("slavePingDataSource") DataSource slavePingDataSource,   // ★ [수정] 핑 전용 주입
            DbStatusManager dbStatusManager) {
        this.masterPingDataSource = masterPingDataSource;
        this.slavePingDataSource = slavePingDataSource;
        this.dbStatusManager = dbStatusManager;
    }

    // 1초마다 실행
    @Scheduled(fixedDelay = 1000)
    public void checkDbHealth() { // 메서드 이름 변경 (Master만 하는 게 아니니까)

        // 1. Master 체크 (Ping용 DS 사용)
        boolean masterAlive = checkConnection(masterPingDataSource);
        dbStatusManager.setMasterAlive(masterAlive);

        // 2. Slave 체크 (Ping용 DS 사용)
        boolean slaveAlive = checkConnection(slavePingDataSource);
        dbStatusManager.setSlaveAlive(slaveAlive);
    }

    private boolean checkConnection(DataSource dataSource) {
        // try-with-resources 구문 (자동 close)
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            stmt.setQueryTimeout(1); // 쿼리 타임아웃
            stmt.executeQuery("SELECT 1 FROM DUAL");

            return true; // 성공
        } catch (Exception e) {
            // 1초(ConnectionTimeout) 안에 연결 못하면 여기로 떨어짐
            return false;
        }
    }
}