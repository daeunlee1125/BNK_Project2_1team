package kr.co.api.backend.service;

import kr.co.api.backend.dto.RateDTO;
import kr.co.api.backend.mapper.RateMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class RateService {

    private final RateMapper rateMapper;

    @Value("${eximbank.api.base-url}")
    private String baseUrl;

    @Value("${eximbank.api.auth-key}")
    private String authKey;

    private final WebClient webClient = WebClient.builder().build();

    // 트랜잭션 문제일 수 있으니 테스트를 위해 잠시 주석 처리 해보세요.
    // (정상 동작하면 다시 주석 해제)
    // @Transactional // 테스트 중에는 주석 처리 유지
    public void collectTodayRate() {

        String today = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);

//        log.info(">>> [API 호출 시작] 날짜: {}", today);

        List<Map<String, Object>> response = webClient.get()
                .uri(baseUrl + "?authkey=" + authKey + "&searchdate=" + today + "&data=AP01")
                .retrieve()
                .bodyToMono(List.class)
                .block();

        if (response == null || response.isEmpty()) {
//            log.info("[RATE] API 응답 없음");
            return;
        }

        LocalDate regDate = LocalDate.now();
        int insertCount = 0;
        int skipCount = 0;

        // [디버깅] 첫 번째 데이터의 키값들 전체 출력 (대소문자 확인용)
        if (!response.isEmpty()) {
//            log.info(">>> [데이터 검증] 첫번째 Row Keys: {}", response.get(0).keySet());
        }

        for (Map<String, Object> item : response) {

            // 1. 대소문자 무관하게 값 가져오기 위한 유틸 사용
            String currencyRaw = getString(item, "CUR_UNIT"); // 아래 유틸 메소드 확인

            if (currencyRaw == null || currencyRaw.isBlank()) {
                // 여기서 걸리면 로그를 찍어서 확인
//                log.warn(">>> [SKIP] 통화코드(CUR_UNIT) 없음. 해당 Row 데이터: {}", item);
                continue;
            }

            String currency = currencyRaw.replace("(100)", "").trim();

            // 2. 중복 체크
            if (rateMapper.existsTodayRate(currency, regDate) > 0) {
                skipCount++;
                continue;
            }

            try {
                RateDTO dto = new RateDTO();
                dto.setRhistCurrency(currency);

                // [수정] getString, getDouble, getInt 유틸 메소드 사용
                dto.setRhistCurName(getString(item, "CUR_NM"));

                dto.setRhistBaseRate(getDouble(item, "DEAL_BAS_R"));
                dto.setRhistBkprRate(getInt(item, "BKPR"));
                dto.setRhistTtBuyRate(getDouble(item, "TTB"));
                dto.setRhistTtSellRate(getDouble(item, "TTS"));
                dto.setRhistSmbsBaseRate(getDouble(item, "KFTC_DEAL_BAS_R"));
                dto.setRhistSmbsBkprRate(getInt(item, "KFTC_BKPR"));

                dto.setRhistRegDt(regDate);
                dto.setRhistAnnounceNo(1);

                rateMapper.insertRate(dto);
                insertCount++;
//                log.info(">>> [INSERT] 저장 성공: {}", currency);

            } catch (Exception e) {
//                log.error(">>> [ERROR] {} 저장 실패: {}", currency, e.getMessage());
            }
        }


    }

    // ==========================================
    //  [안전한 파싱 헬퍼 메소드들] - 아래 메소드들을 클래스 하단에 추가하세요
    // ==========================================

    // 대소문자 구분 없이 key를 찾아서 String 반환
    private String getString(Map<String, Object> map, String key) {
        if (map.get(key) != null) return map.get(key).toString();
        if (map.get(key.toLowerCase()) != null) return map.get(key.toLowerCase()).toString();
        return null;
    }

    // 대소문자 구분 없이 key를 찾아서 Double 반환
    private Double getDouble(Map<String, Object> map, String key) {
        String val = getString(map, key);
        if (val == null || val.isBlank()) return null;
        return Double.parseDouble(val.replace(",", "").trim());
    }

    // 대소문자 구분 없이 key를 찾아서 int 반환
    private int getInt(Map<String, Object> map, String key) {
        String val = getString(map, key);
        if (val == null || val.isBlank()) return 0;
        return Integer.parseInt(val.replace(",", "").trim());
    }
}