package kr.co.api.backend.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Slf4j
public class ReplicationRoutingDataSource extends AbstractRoutingDataSource {

    private final DbStatusManager dbStatusManager;

    public ReplicationRoutingDataSource(DbStatusManager dbStatusManager) {
        this.dbStatusManager = dbStatusManager;
    }

    @Override
    protected Object determineCurrentLookupKey() {
        //@Transactional(readOnly = true) 인지 확인
        boolean isReadOnly = TransactionSynchronizationManager.isCurrentTransactionReadOnly();

        boolean masterAlive = dbStatusManager.isMasterAlive();
        boolean slaveAlive = dbStatusManager.isSlaveAlive();

        // Master 장애 -> Slave
        if (!masterAlive) {
            if (!slaveAlive) {
                log.error("💀 [CRITICAL] Master/Slave 모두 사망. 서비스 불가능.");
                return null;
            }
            return "slave";
        }

        // Slave 장애 -> Master
        if (!slaveAlive) {
            if (!masterAlive) {
                log.error("💀 [CRITICAL] Master/Slave 모두 사망. 서비스 불가능.");
                return null;
            }
            return "master";
        }

        // 둘 다 정상 -> Read/Write 분리
        return isReadOnly ? "slave" : "master";
    }
}