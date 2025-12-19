package kr.co.api.backend.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class FrgnExchOnlineDTO {

    private Long exchOnlineNo;        // 온라인 환전 거래 번호
    private String exchCustCode;      // 고객 코드

    private String exchKrwAcctNo;     // 원화 계좌 번호
    private String exchFrgnAcctNo;    // 외화 모체 계좌 번호
    private String exchFrgnBalNo;     // 외화 자식 계좌 번호

    private String exchType;          // 환전 유형 (B: 매수, S: 매도)

    private String exchFromCurrency;  // 환전 전 통화
    private String exchToCurrency;    // 환전 후 통화

    private Long exchKrwAmount;       // 원화 금액
    private Long exchFrgnAmount;      // 외화 금액

    private Double exchAppliedRate;   // 적용 환율
    private Integer exchStatus;        // 처리 상태

    private LocalDate exchReqDt;       // 환전 요청 일시
}
