package kr.co.api.backend.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;

@Slf4j
public class ReplicationRoutingDataSource extends AbstractRoutingDataSource {

    private final DbStatusManager dbStatusManager;

    public ReplicationRoutingDataSource(DbStatusManager dbStatusManager) {
        this.dbStatusManager = dbStatusManager;
    }

    @Override
    protected Object determineCurrentLookupKey() {
        boolean masterAlive = dbStatusManager.isMasterAlive();
        boolean slaveAlive = dbStatusManager.isSlaveAlive();

        // 기본적 Master 사용
        if (masterAlive) {
            return "master";
        }

        // 2. Master 장애 발생 시 -> Slave로 Failover
        log.warn("[Failover] Master DB 장애 감지! Slave DB로 전환합니다.");

        if (slaveAlive) {
            return "slave";
        }

        // 3. Master/Slave 모두 사망 (서비스 불가)
        log.error("💀 [CRITICAL] 모든 DB(Master/Slave) 연결 불가. 서비스가 중단됩니다.");
        return null;
    }
}