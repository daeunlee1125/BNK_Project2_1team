package kr.co.api.backend.controller;

import kr.co.api.backend.dto.CustInfoDTO;
import kr.co.api.backend.jwt.JwtTokenProvider;
import kr.co.api.backend.service.CustInfoService;
import kr.co.api.backend.service.MobileMember;
import kr.co.api.backend.service.SmsService;
import kr.co.api.backend.util.AesUtil;
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
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@RestController // HTML이 아닌 JSON 데이터를 반환하는 컨트롤러
@RequestMapping("/api/mobile/member")
@RequiredArgsConstructor
public class MobileMemberController {

    private final CustInfoService custInfoService;
    private final JwtTokenProvider jwtTokenProvider;
    private final MobileMember mobileMember;
    private final SmsService smsService;

    // [중요] 인증번호 임시 저장소 (메모리 DB 역할)
    // Key: userId (누가 요청했는지), Value: code (생성된 인증번호)
    // 왜 userId를 키로 쓸까요? -> 한 사용자는 하나의 인증번호만 유효하게 관리하기 위해서입니다.
    private final ConcurrentHashMap<String, String> authCodeStore = new ConcurrentHashMap<>();

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
            // DB에 저장된 DeviceID와 요청온 DeviceID를 비교
            Boolean checkId = mobileMember.login(request);
            Map<String, Object> response = new HashMap<>();
            if(checkId){
                log.info("인증 성공. 토큰 생성 중...");

                // 2. JWT 토큰 생성
                String token = jwtTokenProvider.createToken(custInfoDTO.getCustCode(), "USER", custInfoDTO.getCustName());

                // 3. 모바일 앱에 돌려줄 응답 데이터 구성

                response.put("status", "SUCCESS");
                response.put("token", token);
                response.put("custName", custInfoDTO.getCustName());
                response.put("message", "로그인 성공");

                // 로그인 기록 저장
                custInfoService.saveLastLogin(custInfoDTO.getCustId());
                return ResponseEntity.ok(response);
            }else {
                log.info("다른 기기로 접근하여 추가 인증이 필요합니다.");

                response.put("status", "NEW_DEVICE");
                response.put("message", "등록되지 않은 기기입니다. 추가 인증이 필요합니다.");
                return ResponseEntity.ok(response);
            }

        } else {
            return ResponseEntity.status(401).body("아이디 또는 비밀번호가 일치하지 않습니다.");
        }
    }

    /*
     * [STEP 1] 기기 등록용 SMS 발송 요청
     * * 동작 방식:
     * 1. 앱에서 로그인한 아이디(userId)만 서버로 보냅니다. (전화번호는 안 보냄!)
     * 2. 서버는 그 아이디로 DB를 조회해서 "아, 이 사람 전화번호가 010-1234-5678이구나" 하고 알아냅니다.
     * 3. 그 번호로 인증번호를 쏩니다.
     * * 왜 이렇게 하나요? (보안)
     * -> 만약 앱에서 전화번호를 입력받게 하면, 해커가 본인 폰 번호를 입력해서 인증을 통과할 수 있기 때문입니다.
     */
    @PostMapping("/auth/send-code")
    public ResponseEntity<?> sendAuthCode(@RequestBody Map<String, String> request) {
        String userId = request.get("userid");

        // 1. 사용자 정보 조회 (DB에 있는 진짜 전화번호를 알기 위해)
        CustInfoDTO user = mobileMember.getCustInfoByCustId(userId);

        if (user == null) {
            return ResponseEntity.status(404).body(Map.of("message", "사용자 정보를 찾을 수 없습니다."));
        }

        // 2. DB에서 가져온 '신뢰할 수 있는' 전화번호
        String phoneNumber = AesUtil.decrypt(user.getCustHp());

        if (phoneNumber == null || phoneNumber.isEmpty()) {
            return ResponseEntity.status(400).body(Map.of("message", "등록된 전화번호가 없습니다."));
        }

        // 3. 랜덤 인증번호 6자리 생성 (예: "123456")
        String code = String.format("%06d", new Random().nextInt(999999));

        try {
            // 4. SMS 발송 (DB에서 가져온 번호로 전송됨)
            smsService.sendVerificationCode(phoneNumber, code);

            // 5. [핵심] 서버 메모리에 "이 아이디(userId)의 인증번호는 이거(code)다"라고 적어둠.
            authCodeStore.put(userId, code);

            // 6. 앱 화면에 보여줄 마스킹된 번호 생성 (예: 010-****-5678)
            String maskedPhone = maskPhoneNumber(phoneNumber);

            return ResponseEntity.ok(Map.of(
                    "status", "SUCCESS",
                    "message", "인증번호가 발송되었습니다.",
                    "maskedPhone", maskedPhone // 앱에서는 이 번호로 문자가 갔다고 알려줍니다.
            ));

        } catch (Exception e) {
            log.error("SMS 발송 실패", e);
            return ResponseEntity.status(500).body(Map.of("message", "SMS 발송 중 오류가 발생했습니다."));
        }
    }

    /*
     * [STEP 2] 인증번호 검증 및 확인
     * * 동작 방식:
     * 1. 사용자가 문자로 온 번호를 앱에 입력합니다.
     * 2. 앱은 아이디(userId)와 입력한 번호(code)를 서버로 보냅니다.
     * 3. 서버는 아까 저장해둔(authCodeStore) 값과 비교합니다.
     */
    @PostMapping("/auth/verify-code")
    public ResponseEntity<?> verifyAuthCode(@RequestBody Map<String, String> request) {
        String userId = request.get("userid");
        String inputCode = request.get("code"); // 사용자가 입력한 값

        // 1. 아까 저장해둔 인증번호 꺼내오기
        String savedCode = authCodeStore.get(userId);

        // 2. 비교 로직
        // savedCode != null : 발송 기록이 있어야 함
        // savedCode.equals(inputCode) : 저장된 값과 입력값이 같아야 함
        if (savedCode != null && savedCode.equals(inputCode)) {

            // 3. 인증 성공!
            // 보안을 위해 사용한 인증번호는 즉시 삭제합니다. (재사용 방지)
            authCodeStore.remove(userId);

            return ResponseEntity.ok(Map.of("status", "SUCCESS"));
        } else {
            // 4. 인증 실패 (번호가 틀렸거나, 만료되었거나, 발송 요청을 안 했거나)
            return ResponseEntity.ok(Map.of("status", "FAIL", "message", "인증번호가 일치하지 않습니다."));
        }
    }

    // 전화번호 마스킹 유틸 (01012345678 -> 010-****-5678)
    private String maskPhoneNumber(String phone) {
        if (phone == null || phone.length() < 10) return phone;
        String cleanPhone = phone.replaceAll("-", "");
        if (cleanPhone.length() == 11) {
            return cleanPhone.substring(0, 3) + "-****-" + cleanPhone.substring(7);
        }
        return phone;
    }

    /*
     * [STEP 3] 기기 등록 및 최종 로그인 처리
     * 인증번호 검증(verify-code)을 통과한 후 클라이언트가 호출
     */
    @PostMapping("/register-device")
    public ResponseEntity<?> registerDevice(@RequestBody LoginRequest request) {
        log.info("📱 기기 등록 요청 - ID: {}, DeviceID: {}", request.getUserid(), request.getDeviceId());

        // 1. 아이디/비번 재검증 (보안)
        CustInfoDTO user = custInfoService.login(request.getUserid(), request.getPassword());
        if (user == null) {
            return ResponseEntity.status(401).body("인증 실패");
        }

        // 2. DB에 기기 ID 업데이트
        mobileMember.modifyCustInfoByDeviceId(user.getCustId(), request.getDeviceId());

        // 3. 토큰 발급
        String token = jwtTokenProvider.createToken(user.getCustCode(), "USER", user.getCustName());

        Map<String, Object> response = new HashMap<>();
        response.put("status", "SUCCESS");
        response.put("token", token);
        response.put("custName", user.getCustName());
        response.put("message", "기기 등록 및 로그인 완료");

        // 로그인 기록 저장
        custInfoService.saveLastLogin(user.getCustId());

        return ResponseEntity.ok(response);
    }
}