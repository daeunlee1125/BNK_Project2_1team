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
        boolean isReadOnly = TransactionSynchronizationManager.isCurrentTransactionReadOnly();

        boolean masterAlive = dbStatusManager.isMasterAlive();
        boolean slaveAlive = dbStatusManager.isSlaveAlive();

        // -------------------------------------------------------
        // 시나리오 1: Master 사망 -> 무조건 Slave (선택권 없음)
        // -------------------------------------------------------
        if (!masterAlive) {
            if (!slaveAlive) {
                log.error("💀 [CRITICAL] Master/Slave 모두 사망. 서비스 불가능.");
                return null; // 예외 발생
            }
            return "slave";
        }

        // -------------------------------------------------------
        // 시나리오 2: Slave 사망 -> 무조건 Master (읽기도 Master가 처리)
        // -------------------------------------------------------
        if (!slaveAlive) {
            return "master";
        }

        // -------------------------------------------------------
        // 시나리오 3: 둘 다 생존 (정상) -> Read/Write 분리
        // -------------------------------------------------------
        return isReadOnly ? "slave" : "master";
    }
}