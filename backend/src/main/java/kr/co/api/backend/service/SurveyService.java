package kr.co.api.backend.service;

import kr.co.api.backend.dto.survey.*;
import kr.co.api.backend.mapper.SurveyMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SurveyService {

    // “유형 결과”를 TB_SURVEY_RESP_DTL에 저장할 때 쓰는 가상 문항 ID(너희 테이블 설계에 맞춰둔 값)
    private static final Long RESULT_Q_ID = 10L;

    // opt_id(유형) 값들 (네가 준 값 그대로)
    private static final Long TYPE_STABLE = 38L;
    private static final Long TYPE_LIQUID = 39L;
    private static final Long TYPE_FX = 40L;
    private static final Long TYPE_OVERSEAS = 41L;
    private static final Long TYPE_EVENT = 42L;

    private final SurveyMapper surveyMapper;

    public SurveyDetailResponseDTO getSurveyDetail(Long surveyId) {
        SurveyDetailResponseDTO detail = surveyMapper.selectSurveyById(surveyId);
        if (detail == null) return null;

        List<SurveyQuestionResponseDTO> questions = surveyMapper.selectSurveyQuestions(surveyId);
        for (SurveyQuestionResponseDTO q : questions) {
            q.setOptions(surveyMapper.selectQuestionOptions(q.getQId()));
        }
        detail.setQuestions(questions);
        return detail;
    }

    @Transactional
    public void submitSurveyResponse(Long surveyId, SurveyResponseRequestDTO request) {
        // ===== 0) 요청 기본 검증 =====
        if (request == null) {
            throw new IllegalArgumentException("request body is null");
        }
        if (request.getCustCode() == null || request.getCustCode().isBlank()) {
            throw new IllegalArgumentException("custCode is required");
        }

        List<SurveyAnswerRequestDTO> answers = Optional.ofNullable(request.getAnswers())
                .orElseGet(Collections::emptyList);

        log.info("[SURVEY] submit start surveyId={}, custCode={}, answers.size={}",
                surveyId, request.getCustCode(), answers.size());

        // ===== 1) 요청 answers에서 qId 누락/이상치 즉시 잡기 =====
        for (int i = 0; i < answers.size(); i++) {
            SurveyAnswerRequestDTO a = answers.get(i);
            if (a == null) {
                throw new IllegalArgumentException("answers[" + i + "] is null");
            }
            if (a.getQId() == null) {
                // 여기 걸리면 “클라에서 qId가 빠졌거나, Jackson이 매핑을 못했거나” 둘 중 하나
                throw new IllegalArgumentException("answers[" + i + "].qId is null");
            }
        }

        // ===== 2) respId 확보 =====
        Long respId = surveyMapper.selectResponseId(surveyId, request.getCustCode());
        if (respId != null) {
            surveyMapper.deleteResponseDetails(respId);
            surveyMapper.updateResponseHeaderStatus(respId, "DONE");
        } else {
            SurveyResponseHeaderDTO header = new SurveyResponseHeaderDTO();
            header.setSurveyId(surveyId);
            header.setCustCode(request.getCustCode());
            header.setStatus("DONE");
            surveyMapper.insertResponseHeader(header);
            respId = header.getRespId();

            if (respId == null) {
                throw new IllegalStateException("respId generation failed (insertResponseHeader returned null respId)");
            }
        }

        // ===== 3) details 생성 (null optId 제거, 텍스트는 blank 제거) =====
        List<SurveyResponseDetailDTO> details = new ArrayList<>();

        for (int i = 0; i < answers.size(); i++) {
            SurveyAnswerRequestDTO answer = answers.get(i);

            // optIds형
            if (answer.getOptIds() != null && !answer.getOptIds().isEmpty()) {
                for (Long optId : answer.getOptIds()) {
                    if (optId == null) {
                        log.warn("[SURVEY] skip null optId: answers[{}].qId={}", i, answer.getQId());
                        continue;
                    }
                    SurveyResponseDetailDTO d = new SurveyResponseDetailDTO();
                    d.setRespId(respId);
                    d.setQId(answer.getQId());
                    d.setOptId(optId);
                    details.add(d);
                }
            }
            // answerText형
            else if (answer.getAnswerText() != null && !answer.getAnswerText().isBlank()) {
                SurveyResponseDetailDTO d = new SurveyResponseDetailDTO();
                d.setRespId(respId);
                d.setQId(answer.getQId());
                d.setAnswerText(answer.getAnswerText());
                details.add(d);
            }
            // 둘 다 없으면 그냥 스킵
        }

        // ===== 4) 유형 결과 1건 추가 =====
        Long typeOptId = deriveTypeOptId(answers);
        if (typeOptId == null) typeOptId = TYPE_STABLE;

        SurveyResponseDetailDTO result = new SurveyResponseDetailDTO();
        result.setRespId(respId);
        result.setQId(RESULT_Q_ID);
        result.setOptId(typeOptId);
        details.add(result);

        // ===== 5) INSERT 직전 최종 검증 + 로그 =====
        for (int i = 0; i < details.size(); i++) {
            SurveyResponseDetailDTO d = details.get(i);
            if (d.getRespId() == null) {
                throw new IllegalStateException("details[" + i + "].respId is null");
            }
            if (d.getQId() == null) {
                // 여기서 잡히면 “서비스에서 만든 details가 이미 깨진 상태”라서 바로 원인 특정 가능
                throw new IllegalStateException("details[" + i + "].qId is null (respId=" + d.getRespId()
                        + ", optId=" + d.getOptId() + ", answerText=" + d.getAnswerText() + ")");
            }
            log.info("[SURVEY] details[{}] respId={}, qId={}, optId={}, answerText={}",
                    i, d.getRespId(), d.getQId(), d.getOptId(), d.getAnswerText());
        }

        // ===== 6) 저장 =====
        if (!details.isEmpty()) {
            surveyMapper.insertResponseDetails(details);
        }

        log.info("[SURVEY] submit done surveyId={}, custCode={}, respId={}, insertedRows={}",
                surveyId, request.getCustCode(), respId, details.size());
    }

    private Long deriveTypeOptId(List<SurveyAnswerRequestDTO> answers) {
        List<Long> optIds = answers.stream()
                .filter(Objects::nonNull)
                .flatMap(a -> Optional.ofNullable(a.getOptIds()).orElseGet(Collections::emptyList).stream())
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        if (optIds.isEmpty()) return TYPE_STABLE;

        List<SurveyOptionValueDTO> optionValues = surveyMapper.selectOptionValues(optIds);

        Map<Long, List<String>> valuesByQId = new HashMap<>();
        for (SurveyOptionValueDTO option : optionValues) {
            if (option == null) continue;
            if (option.getQId() == null) continue;
            valuesByQId.computeIfAbsent(option.getQId(), k -> new ArrayList<>())
                    .add(option.getOptValue());
        }

        if (containsValue(valuesByQId, 3L, "LIQ_NEED")) return TYPE_LIQUID;

        if (containsValue(valuesByQId, 1L, "GOAL_STABLE")) return TYPE_STABLE;
        if (containsValue(valuesByQId, 1L, "GOAL_FX")) return TYPE_FX;
        if (containsValue(valuesByQId, 1L, "GOAL_OVERSEAS")) return TYPE_OVERSEAS;
        if (containsValue(valuesByQId, 1L, "GOAL_EVENT")) return TYPE_EVENT;

        if (containsValue(valuesByQId, 2L, "PRIOR_LIQ")) return TYPE_LIQUID;
        if (containsValue(valuesByQId, 2L, "PRIOR_RATE")) return TYPE_STABLE;
        if (containsValue(valuesByQId, 2L, "PRIOR_FX")) return TYPE_FX;
        if (containsValue(valuesByQId, 2L, "PRIOR_EVENT")) return TYPE_EVENT;

        return TYPE_STABLE;
    }

    private boolean containsValue(Map<Long, List<String>> valuesByQId, Long qId, String target) {
        return valuesByQId.getOrDefault(qId, Collections.emptyList()).contains(target);
    }
}
