package kr.co.api.backend.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class RateDTO {


    // 히스토리 번호
    private int rhistNo;

    // 통화 코드
    private String rhistCurrency;

    // 통화명
    private String rhistCurName;

    // 매매 기준율
    private Double rhistBaseRate;

    // 장부가격
    private int rhistBkprRate;

    // 전신환 매입환율
    private Double rhistTtBuyRate;

    // 전신환 매도환율
    private Double rhistTtSellRate;

    // 서울외국환중개 매매기준율
    private Double rhistSmbsBaseRate;

    // 서울외국환중개 장부가격
    private int rhistSmbsBkprRate;

    // 적용일시
    private LocalDate rhistRegDt;

    // 고시회차
    private int rhistAnnounceNo;







}
