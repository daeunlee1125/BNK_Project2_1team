package kr.co.api.backend.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DbStatusManager {

    private boolean isMasterAlive = true; // 기본값: Master 살아있음
    private boolean isSlaveAlive = true;

    public boolean isMasterAlive() {
        return this.isMasterAlive;
    }

    public boolean isSlaveAlive() {
        return this.isSlaveAlive;
    }

    public void setMasterAlive(boolean alive) {
        // 상태가 변할 때만 로그 출력
        if (this.isMasterAlive != alive) {
            if (alive) {
                log.info("✅ [DB RECOVERY] Master DB가 복구되었습니다! 정상 모드로 전환합니다.");
            } else {
                log.error("🚨 [DB FAILOVER] Master DB 장애 발생! Slave DB를 메인으로 승격합니다.");
            }
        }
        this.isMasterAlive = alive;
    }

    // Slave 상태 변경 로직
    public void setSlaveAlive(boolean alive) {
        if (this.isSlaveAlive != alive) {
            if (alive) log.info("✅ [DB RECOVERY] Slave DB 복구됨! 읽기 분산 재개.");
            else log.warn("⚠️ [DB FALLBACK] Slave DB 사망! Master가 읽기까지 수행.");
        }
        this.isSlaveAlive = alive;
    }
}

