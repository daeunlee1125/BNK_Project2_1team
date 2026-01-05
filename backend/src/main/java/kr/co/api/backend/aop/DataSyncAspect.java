package kr.co.api.backend.aop;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.CodeSignature;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import kr.co.api.backend.config.DbStatusManager;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Aspect
@Component
@Slf4j
public class DataSyncAspect {

    private final SqlSessionTemplate primarySqlSession;
    private final SqlSessionTemplate slaveSqlSession;
    private final PlatformTransactionManager slaveTransactionManager;
    private final DbStatusManager dbStatusManager;

    @Autowired
    public DataSyncAspect(
            SqlSessionTemplate primarySqlSession,
            @Qualifier("slaveSqlSessionTemplate") SqlSessionTemplate slaveSqlSession,
            @Qualifier("slaveTransactionManager") PlatformTransactionManager slaveTransactionManager,
            @Qualifier("realSlaveDataSource") DataSource slaveDataSource,
            DbStatusManager dbStatusManager
    ) {
        this.primarySqlSession = primarySqlSession;
        this.slaveSqlSession = slaveSqlSession;
        this.slaveTransactionManager = slaveTransactionManager;
        this.dbStatusManager = dbStatusManager;
    }

    @Around("@annotation(kr.co.api.backend.annotation.CoreBanking)")
    public Object syncToSlave(ProceedingJoinPoint joinPoint) throws Throwable {

        // 1. Master DB(Main) 로직 먼저 수행
        Object result = joinPoint.proceed();

        // ---------------------------------------------------------
        // 2. Master DB 반영 성공 후, Slave DB 동기화(Replication) 시작
        // ---------------------------------------------------------

        // [예외 케이스 1] 현재 Master가 죽어서 로직이 이미 Slave에서 돌았을 경우 -> 동기화 불필요
        if (!dbStatusManager.isMasterAlive()) {
            log.warn("⚠️ [Skip Sync] Master 장애 상태. 로직이 이미 Slave에서 수행되었습니다.");
            return result;
        }

        // [예외 케이스 2] Slave가 죽어있는 경우 -> 동기화 시도 시 에러 나므로 패스 (Master 데이터만 유지)
        if (!dbStatusManager.isSlaveAlive()) {
            log.error("⛔ [Skip Sync] Slave DB 연결 불가. 동기화를 건너뜁니다. (Master에만 저장됨)");
            return result;
        }

        // Slave 전용 트랜잭션 시작
        TransactionStatus status = null;
        try {
            String mapperId = getMapperId(joinPoint);
            Object[] args = joinPoint.getArgs();
            String methodName = joinPoint.getSignature().getName();

            // Slave 트랜잭션 오픈
            status = slaveTransactionManager.getTransaction(new DefaultTransactionDefinition());

            // 파라미터 매핑 로직
            Object parameterObject;
            if (args == null || args.length == 0) {
                parameterObject = null;
            } else if (args.length == 1) {
                parameterObject = args[0];
            } else {
                Map<String, Object> paramMap = new HashMap<>();
                CodeSignature codeSignature = (CodeSignature) joinPoint.getSignature();
                String[] paramNames = codeSignature.getParameterNames();
                for (int i = 0; i < args.length; i++) {
                    paramMap.put(paramNames[i], args[i]);
                    paramMap.put("param" + (i + 1), args[i]);
                }
                parameterObject = paramMap;
            }

            // 메서드 이름에 따른 CRUD 분기 (MyBatis ID 호출)
            if (methodName.startsWith("insert")) {
                slaveSqlSession.insert(mapperId, parameterObject);
            } else if (methodName.startsWith("update")) {
                slaveSqlSession.update(mapperId, parameterObject);
            } else if (methodName.startsWith("delete")) {
                slaveSqlSession.delete(mapperId, parameterObject);
            }

            // Slave 커밋
            slaveTransactionManager.commit(status);

            // 실시간 동기화 성공 시각화
            log.info("✅ [이중 쓰기 성공] Master 데이터가 Slave로 즉시 동기화되었습니다. (메서드: {})", methodName);

        } catch (Exception e) {
            // 동기화 실패 시 Slave만 롤백하고, 메인 로직(Master)은 성공 처리하여 서비스 중단 방지
            if (status != null) slaveTransactionManager.rollback(status);

            // 실패 상황 명시
            log.error("❌ [이중 쓰기 실패] Slave 동기화에 실패했습니다. (메인 트랜잭션은 유지됨) : {}", e.getMessage());
        }

        return result;
    }

    private String getMapperId(ProceedingJoinPoint joinPoint) {
        Class<?>[] interfaces = joinPoint.getTarget().getClass().getInterfaces();
        return (interfaces.length > 0 ? interfaces[0].getName() : "") + "." + joinPoint.getSignature().getName();
    }
}