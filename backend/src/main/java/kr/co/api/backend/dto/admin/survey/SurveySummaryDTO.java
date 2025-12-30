package kr.co.api.backend.dto.admin.survey;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class SurveySummaryDTO {
    private Long surveyId;
    private String title;
    private String description;
    private String isActive;
    private Integer questionCount;
    private LocalDateTime createdAt;
    private String createdBy;
    private LocalDateTime updatedAt;
    private String updatedBy;
}
