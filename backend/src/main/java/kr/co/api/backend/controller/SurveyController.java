package kr.co.api.backend.controller;

import kr.co.api.backend.dto.survey.SurveyDetailResponseDTO;
import kr.co.api.backend.dto.survey.SurveyResponseRequestDTO;
import kr.co.api.backend.service.SurveyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/surveys")
@RequiredArgsConstructor
public class SurveyController {

    private final SurveyService surveyService;

    @GetMapping("/{surveyId}")
    public ResponseEntity<SurveyDetailResponseDTO> getSurvey(@PathVariable Long surveyId) {
        SurveyDetailResponseDTO detail = surveyService.getSurveyDetail(surveyId);
        if (detail == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(detail);
    }

    @PostMapping("/{surveyId}/responses")
    public ResponseEntity<Void> submitSurveyResponse(
            @PathVariable Long surveyId,
            @RequestBody SurveyResponseRequestDTO request
    ) {
        surveyService.submitSurveyResponse(surveyId, request);
        return ResponseEntity.ok().build();
    }
}
