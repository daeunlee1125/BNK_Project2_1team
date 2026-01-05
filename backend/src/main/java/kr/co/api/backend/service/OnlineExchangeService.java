package kr.co.api.backend.service;

import kr.co.api.backend.dto.*;
import kr.co.api.backend.mapper.OnlineExchangeMapper;
import kr.co.api.backend.service.async.LogProducer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class OnlineExchangeService {

    private final OnlineExchangeMapper onlineExchangeMapper;
    private final LogProducer logProducer; // Redis Producer
    private final ObjectMapper objectMapper; // Spring Boot에 기본 내장됨

    // 온라인 환전 처리
    @Transactional
    public void processOnlineExchange(FrgnExchOnlineDTO dto, String custCode) {
        if (custCode == null) {
            throw new IllegalStateException("고객 정보를 찾을 수 없습니다.");
        }

        // DTO에 고객 코드 세팅
        dto.setExchCustCode(custCode);

        log.info("환전 요청: " + dto.toString());

        String custName = onlineExchangeMapper.selectCustNameByCustCode(custCode);

        if (custName == null) {
            throw new IllegalStateException("고객 이름을 조회할 수 없습니다.");
        }

        /* =======================================================
           기준 통화(외화) 결정 로직을 최상단으로 이동
           - 사기(B): 원화 -> 외화(To) => 외화 코드는 To
           - 팔기(S): 외화(From) -> 원화 => 외화 코드는 From
           ======================================================= */
        String targetCurrency = "B".equals(dto.getExchType())
                ? dto.getExchToCurrency()
                : dto.getExchFromCurrency();

        /* =========================
           1. 환율 조회
           ========================= */
        // dto.getExchToCurrency() 대신 위에서 구한 targetCurrency(외화코드) 사용
        RateDTO rate = onlineExchangeMapper.selectLatestRate(targetCurrency);

        if (rate == null) {
            throw new IllegalStateException("환율 정보를 조회할 수 없습니다. (통화코드: " + targetCurrency + ")");
        }

        /* =========================
           2. 원화 계좌 잠금 조회
           ========================= */
        CustAcctDTO krwAcct = onlineExchangeMapper.selectKrwAcctForUpdate(custCode);

        if (krwAcct == null) {
            throw new IllegalStateException("원화 계좌를 찾을 수 없습니다.");
        }

        // 원화 계좌번호 DTO에 세팅 (이거 없으면 에러남)
        dto.setExchKrwAcctNo(krwAcct.getAcctNo());

        /* =========================
           3. 외화 자식 계좌 잠금 조회
           ========================= */
        FrgnAcctDTO frgnAcctDTO = onlineExchangeMapper.selectMyFrgnAccount(custCode);

        // 외화 계좌번호 DTO에 세팅
        dto.setExchFrgnBalNo(frgnAcctDTO.getFrgnAcctNo());
        dto.setExchFrgnAcctNo(frgnAcctDTO.getFrgnAcctNo());

        // 위에서 결정한 targetCurrency 사용
        FrgnAcctBalanceDTO frgnBalance = onlineExchangeMapper.selectFrgnBalanceForUpdate(
                dto.getExchFrgnBalNo(),
                targetCurrency
        );

        // 팔기일 때는 외화 잔액이 필수이므로 체크, 사기일 때는 없을 수도 있음(개설 전 등)을 고려해야 하나
        // 현재 로직상 잔액 테이블 로우(row) 자체는 있어야 한다고 가정함.
        if (frgnBalance == null) {
            throw new IllegalStateException("외화 지갑 정보를 찾을 수 없습니다.");
        }

        /* =========================
           4. 환전 처리
           ========================= */
        if ("B".equals(dto.getExchType())) {
            // =====================
            // 외화 매수 (KRW → 외화)
            // =====================
            Long krwAmount = dto.getExchKrwAmount();
            Long currentKrwBalance = krwAcct.getAcctBalance();

            if (currentKrwBalance < krwAmount) {
                throw new IllegalStateException("원화 잔액이 부족합니다.");
            }

            double rateValue = rate.getRhistBaseRate();
            long foreignAmount = (long) (krwAmount / rateValue);

            // 원화 차감
            onlineExchangeMapper.updateKrwAcctBalance(
                    krwAcct.getAcctNo(),
                    currentKrwBalance - krwAmount
            );

            // 외화 증가
            onlineExchangeMapper.updateFrgnBalance(
                    frgnBalance.getBalNo(),
                    frgnBalance.getBalBalance() + foreignAmount
            );

            dto.setExchFrgnAmount(foreignAmount);
            dto.setExchAppliedRate(rateValue);

        } else if ("S".equals(dto.getExchType())) {
            // 1. 사용자 입력값: 얼마를 팔 것인가? (외화 기준)
            Long foreignAmount = dto.getExchFrgnAmount();
            Long currentForeignBalance = frgnBalance.getBalBalance();

            // 2. 잔액 검사: 외화가 충분한가?
            if (currentForeignBalance < foreignAmount) {
                throw new IllegalStateException("외화 잔액이 부족합니다.");
            }

            // 3. 환율 적용 계산: 외화 * 환율 = 원화
            // 실제 은행은 '전신환 매도율(받으실 때)'을 적용하여 BaseRate보다 낮게 쳐줍니다.
            // 현재는 BaseRate를 쓰고 있는데, 학습용으론 괜찮지만 "은행은 싸게 사서 비싸게 판다"는 원리는 기억해두세요.
            double rateValue = rate.getRhistBaseRate();
            long krwAmount = (long) (foreignAmount * rateValue); // 소수점 버림 처리됨

            // 4. 외화 계좌 차감 (내 돈 나감) -> 순서 중요 (출금 먼저)
            onlineExchangeMapper.updateFrgnBalance(
                    frgnBalance.getBalNo(),
                    currentForeignBalance - foreignAmount
            );

            // 5. 원화 계좌 증가 (돈 들어옴)
            onlineExchangeMapper.updateKrwAcctBalance(
                    krwAcct.getAcctNo(),
                    krwAcct.getAcctBalance() + krwAmount
            );

            // 6. 결과값 DTO에 세팅 (이력이 저장될 때 필요)
            dto.setExchKrwAmount(krwAmount);
            dto.setExchAppliedRate(rateValue);

            // 통화 코드 명시
            dto.setExchFromCurrency(targetCurrency); // 파는 돈 (외화, 예: USD)
            dto.setExchToCurrency("KRW");            // 받는 돈 (원화)

        } else {
            throw new IllegalArgumentException("잘못된 환전 유형입니다.");
        }

        // =========================
        // 4-1. 계좌이체 이력 저장 (Master DB 저장 & Slave 비동기 전송)
        // =========================
        if ("B".equals(dto.getExchType())) {
            // [CASE 1] 외화 매수 (Buy)
            // 1. 원화 출금 (Master DB 즉시 저장)
            onlineExchangeMapper.insertCustTranHist(
                    krwAcct.getAcctNo(),
                    custName,
                    2, // 출금
                    dto.getExchKrwAmount(),
                    dto.getExchFrgnAcctNo(),
                    "외화 환전 출금"
            );

            // 1-1. 원화 출금 로그 -> Redis 큐 전송 (Slave 동기화용)
            Map<String, Object> logDataKrw = new HashMap<>();
            logDataKrw.put("log_type", "TRANSFER");
            logDataKrw.put("acctNo", krwAcct.getAcctNo());
            logDataKrw.put("custName", custName);
            logDataKrw.put("tranType", 2);
            logDataKrw.put("amount", dto.getExchKrwAmount());
            logDataKrw.put("recAcctNo", dto.getExchFrgnAcctNo());
            logDataKrw.put("memo", "외화 환전 출금");
            logProducer.sendLog(logDataKrw);

            // 외화 입금 (Master DB 즉시 저장)
            onlineExchangeMapper.insertCustTranHist(dto.getExchFrgnAcctNo(), custName, 1, dto.getExchFrgnAmount(), krwAcct.getAcctNo(), "외화 환전 입금"
            );

            // 외화 입금 로그 -> Redis 큐 전송
            Map<String, Object> logDataFrgn = new HashMap<>();
            logDataFrgn.put("log_type", "TRANSFER");
            logDataFrgn.put("acctNo", dto.getExchFrgnAcctNo());
            logDataFrgn.put("custName", custName);
            logDataFrgn.put("tranType", 1);
            logDataFrgn.put("amount", dto.getExchFrgnAmount());
            logDataFrgn.put("recAcctNo", krwAcct.getAcctNo());
            logDataFrgn.put("memo", "외화 환전 입금");
            logProducer.sendLog(logDataFrgn);

        } else if ("S".equals(dto.getExchType())) {
            // [CASE 2] 외화 매도 (Sell)
            // 1. 외화 출금 (Master DB 즉시 저장)
            onlineExchangeMapper.insertCustTranHist(
                    dto.getExchFrgnAcctNo(),
                    custName,
                    2, // 출금
                    dto.getExchFrgnAmount(),
                    krwAcct.getAcctNo(),
                    "외화 환전 출금"
            );

            // 1-1. 외화 출금 로그 -> Redis 큐 전송
            Map<String, Object> logDataFrgn = new HashMap<>();
            logDataFrgn.put("log_type", "TRANSFER");
            logDataFrgn.put("acctNo", dto.getExchFrgnAcctNo());
            logDataFrgn.put("custName", custName);
            logDataFrgn.put("tranType", 2);
            logDataFrgn.put("amount", dto.getExchFrgnAmount());
            logDataFrgn.put("recAcctNo", krwAcct.getAcctNo());
            logDataFrgn.put("memo", "외화 환전 출금");
            logProducer.sendLog(logDataFrgn);

            // 2. 원화 입금 (Master DB 즉시 저장)
            onlineExchangeMapper.insertCustTranHist(
                    krwAcct.getAcctNo(),
                    custName,
                    1, // 입금
                    dto.getExchKrwAmount(),
                    dto.getExchFrgnAcctNo(),
                    "외화 환전 입금"
            );

            // 2-1. 원화 입금 로그 -> Redis 큐 전송
            Map<String, Object> logDataKrw = new HashMap<>();
            logDataKrw.put("log_type", "TRANSFER");
            logDataKrw.put("acctNo", krwAcct.getAcctNo());
            logDataKrw.put("custName", custName);
            logDataKrw.put("tranType", 1);
            logDataKrw.put("amount", dto.getExchKrwAmount());
            logDataKrw.put("recAcctNo", dto.getExchFrgnAcctNo());
            logDataKrw.put("memo", "외화 환전 입금");
            logProducer.sendLog(logDataKrw);
        }

        /* =========================
           5. 환전 이력 저장
           ========================= */
        dto.setExchStatus(1);
        dto.setExchReqDt(LocalDate.now());

        onlineExchangeMapper.insertOnlineExchange(dto);

        // Slave 동기화를 위해 Redis로 데이터 전송 (비동기)
        try {
            // DTO를 Map으로 변환 (직접 put 해도 되지만 이게 편함)
            Map<String, Object> exchangeMap = objectMapper.convertValue(dto, Map.class);

            // ★ 중요: Worker가 이게 "환전 내역"인지 "이체 내역"인지 알아야 함!
            exchangeMap.put("log_type", "EXCHANGE");

            logProducer.sendLog(exchangeMap); // 큐에 넣기

        } catch (Exception e) {
            log.error("Redis 전송 실패 (환전 내역): {}", e.getMessage());
            // Redis 실패해도 환전 자체는 성공 처리 (로그만 남김)
        }
    }


    @Transactional(readOnly = true)
    public Map<String, Object> getMyExchangeAccounts(String custCode, String currency) {

        if (custCode == null) {
            throw new IllegalStateException("고객 정보를 찾을 수 없습니다.");
        }

        CustAcctDTO krwAcct = onlineExchangeMapper.selectMyKrwAccount(custCode);
        FrgnAcctDTO frgnAcct = onlineExchangeMapper.selectMyFrgnAccount(custCode);

        long krwBalance = (krwAcct != null && krwAcct.getAcctBalance() != null)
                ? krwAcct.getAcctBalance()
                : 0L;

        long frgnBalanceAmount = 0L;

        if (frgnAcct != null && frgnAcct.getFrgnAcctNo() != null) {
            FrgnAcctBalanceDTO frgnBalance = onlineExchangeMapper.selectMyFrgnBalance(
                    frgnAcct.getFrgnAcctNo(),
                    currency
            );

            frgnBalanceAmount = (frgnBalance != null && frgnBalance.getBalBalance() != null)
                    ? frgnBalance.getBalBalance()
                    : 0L;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("krwBalance", krwBalance);
        result.put("frgnBalance", frgnBalanceAmount);
        // 필요하면 계좌번호도 같이
        result.put("krwAcctNo", krwAcct != null ? krwAcct.getAcctNo() : null);
        result.put("frgnAcctNo", frgnAcct != null ? frgnAcct.getFrgnAcctNo() : null);

        return result;
    }




}
