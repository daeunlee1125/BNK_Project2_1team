package kr.co.api.backend.dto;

import lombok.Data;

@Data
public class ReqSignupDTO {
    private CustAcctDTO custAcct;
    private CustInfoDTO custInfo;
}
