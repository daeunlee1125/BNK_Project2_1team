package kr.co.api.backend.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class FrgnAcctDTO {

    private String frgnAcctNo;     // 외화 모계좌 번호
    private String frgnCustCode;   // 고객 코드
    private String frgnRegDt;      // 개설일
}
