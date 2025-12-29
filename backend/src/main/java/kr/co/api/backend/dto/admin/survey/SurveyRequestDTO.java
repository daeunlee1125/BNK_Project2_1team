package kr.co.api.backend.dto.admin.survey;

import lombok.Data;

import java.util.List;

@Data
public class SurveyRequestDTO {
    private String title;
    private String description;
    private String isActive;
    private String createdBy;
    private String updatedBy;
    private List<SurveyQuestionRequestDTO> questions;
}
