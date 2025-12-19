package kr.co.api.backend.controller;

import kr.co.api.backend.dto.FrgnExchOnlineDTO;
import kr.co.api.backend.jwt.CustomUserDetails;
import kr.co.api.backend.service.OnlineExchangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/exchange")
@RequiredArgsConstructor
public class OnlineExchangeController {

    private final OnlineExchangeService onlineExchangeService;

    /**
     * 온라인 환전 요청
     */
    @PostMapping("/online")
    public ResponseEntity<?> onlineExchange(
            @RequestBody FrgnExchOnlineDTO dto
    ) {
        /* =========================
           1. 로그인 사용자(userId) 조회
           ========================= */
        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null ||
                !(authentication.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity
                    .status(401)
                    .body("인증 정보가 없습니다.");
        }

        CustomUserDetails user =
                (CustomUserDetails) authentication.getPrincipal();

        // JWT subject = 로그인 userId
        String userId = user.getUsername();

        /* =========================
           2. 온라인 환전 처리
           ========================= */
        onlineExchangeService.processOnlineExchange(dto, userId);

        /* =========================
           3. 응답
           ========================= */
        return ResponseEntity.ok("온라인 환전이 정상적으로 처리되었습니다.");
    }
}
