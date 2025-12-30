package kr.co.api.backend.mapper;

import kr.co.api.backend.dto.DpstAcctDraftDTO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DpstAcctDraftMapper {

    DpstAcctDraftDTO findLatestDraft(@Param("dpstId") String dpstId, @Param("custCode") String custCode);

    int insertDraft(DpstAcctDraftDTO draft);

    int updateDraft(DpstAcctDraftDTO draft);

    int deleteDraft(@Param("dpstId") String dpstId, @Param("custCode") String custCode);
}
