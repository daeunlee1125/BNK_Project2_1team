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
import org.springframework.transaction.support.TransactionSynchronizationManager;
import kr.co.api.backend.config.DbStatusManager;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;

@Aspect
@Component
@Slf4j
public class DataSyncAspect {

    private final SqlSessionTemplate primarySqlSession;
    private final SqlSessionTemplate slaveSqlSession;
    private final PlatformTransactionManager slaveTransactionManager;
    private final DataSource slaveDataSource;
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
        this.slaveDataSource = slaveDataSource;
        this.dbStatusManager = dbStatusManager;
    }

    @Around("@annotation(kr.co.api.backend.annotation.CoreBanking)")
    public Object syncToSlave(ProceedingJoinPoint joinPoint) throws Throwable {

        Object result = joinPoint.proceed();

        // Master가 죽어있다면? -> 이미 위에서 Slave에 썼으므로 동기화 불필요
        if (!dbStatusManager.isMasterAlive()) {
            log.info(">>>> [CoreBanking Sync] Master 장애 상황. 메인 로직이 Slave를 수행했으므로 동기화 패스.");
            return result;
        }

        // 2. Slave 동기화 시도
        // Slave가 죽었으면 동기화 시도조차 하지 말고 패스
        if (!dbStatusManager.isSlaveAlive()) {
            log.warn(">>>> [CoreBanking Sync] Slave DB 장애 상태. 동기화 건너뜀 (Master에만 저장됨).");
            return result; // 여기서 끝냄
        }

        TransactionStatus status = null;
        try {
            if (TransactionSynchronizationManager.isCurrentTransactionReadOnly()) return result;

            String mapperId = getMapperId(joinPoint);
            Object[] args = joinPoint.getArgs();
            String methodName = joinPoint.getSignature().getName();

            status = slaveTransactionManager.getTransaction(new DefaultTransactionDefinition());
            log.info(">>>> [CoreBanking Sync] 동기화 시작: {}", mapperId);

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

            if (methodName.startsWith("insert")) slaveSqlSession.insert(mapperId, parameterObject);
            else if (methodName.startsWith("update")) slaveSqlSession.update(mapperId, parameterObject);
            else if (methodName.startsWith("delete")) slaveSqlSession.delete(mapperId, parameterObject);

            slaveTransactionManager.commit(status);
            log.info(">>>> [CoreBanking Sync] 동기화 완료! (DB: Slave)");

        } catch (Exception e) {
            if (status != null) slaveTransactionManager.rollback(status);
            log.error(">>>> [CoreBanking Sync] 동기화 실패: {}", e.getMessage());
        }
        return result;
    }

    private String getMapperId(ProceedingJoinPoint joinPoint) {
        Class<?>[] interfaces = joinPoint.getTarget().getClass().getInterfaces();
        return (interfaces.length > 0 ? interfaces[0].getName() : "") + "." + joinPoint.getSignature().getName();
    }
}