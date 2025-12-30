package kr.co.api.backend.mapper;

import kr.co.api.backend.dto.CustInfoDTO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MobileCustInfoMapper {
    int countingDeviceId(String deviceId);
    String selectDeviceIdByCustInfo(String deviceId);
    void updateDeviceIdByCustInfo(String deviceId, String custId);
    CustInfoDTO selectUserIdByCustInfo(String custId);
    void updateCustInfoByPIN(@Param("custId") String custId, @Param("custPin") String custPin);
    void updateCustInfoByBIO(String custId, String bioAuthYn);
    void updateBioAuthYn(String userId, String useYn);
}
