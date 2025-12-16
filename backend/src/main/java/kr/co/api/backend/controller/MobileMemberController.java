package kr.co.api.backend.controller;

import kr.co.api.backend.dto.CustInfoDTO;
import kr.co.api.backend.jwt.JwtTokenProvider;
import kr.co.api.backend.service.CustInfoService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController // HTML이 아닌 JSON 데이터를 반환하는 컨트롤러
@RequestMapping("/api/mobile/member")
@RequiredArgsConstructor
public class MobileMemberController {

    private final CustInfoService custInfoService;
    private final JwtTokenProvider jwtTokenProvider;

    // 모바일 로그인 요청 객체 (DTO)
    @Data
    public static class LoginRequest {
        private String userid;
        private String password;
        private String deviceId; // 앱에서 보낸 기기 고유 ID
    }

    @PostMapping("/login")
    public ResponseEntity<?> mobileLogin(@RequestBody LoginRequest request) {
        log.info("모바일 로그인 요청 - ID: {}, DeviceID: {}", request.getUserid(), request.getDeviceId());

        // 1. 아이디/비밀번호 검증
        CustInfoDTO custInfoDTO = custInfoService.login(request.getUserid(), request.getPassword());

        if (custInfoDTO != null) {
            // [학습 포인트] 여기서 DB에 저장된 DeviceID와 요청온 DeviceID를 비교하는 로직을 추가할 수 있습니다.
            // 지금은 로그만 찍고 넘어갑니다.
            log.info("인증 성공. 토큰 생성 중...");

            // 2. JWT 토큰 생성
            String token = jwtTokenProvider.createToken(custInfoDTO.getCustCode(), "USER", custInfoDTO.getCustName());

            // 3. 모바일 앱에 돌려줄 응답 데이터 구성
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("custName", custInfoDTO.getCustName());
            response.put("message", "로그인 성공");

            // 로그인 기록 저장
            custInfoService.saveLastLogin(custInfoDTO.getCustId());

            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(401).body("아이디 또는 비밀번호가 일치하지 않습니다.");
        }
    }
}