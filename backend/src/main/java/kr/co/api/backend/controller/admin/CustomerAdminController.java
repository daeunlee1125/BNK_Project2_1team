package kr.co.api.backend.controller.admin;

import kr.co.api.backend.service.MemberService; // 회원 서비스가 있다고 가정
import kr.co.api.backend.dto.MemberDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
@RequestMapping("/admin/customer")
public class CustomerAdminController {

    @Autowired
    private MemberService memberService; // 기존 MemberService 활용 (혹은 별도 Service)

    // 고객 관리 페이지 조회
    @GetMapping("/list")
    public String customerList(Model model,
                               @RequestParam(required = false, defaultValue = "") String keyword) {

        // 검색 로직이나 전체 리스트 조회 로직 (기존 서비스 메서드 활용 가정)
        // List<MemberDTO> customers = memberService.findAllMembers(keyword);
        // model.addAttribute("customers", customers);

        // *UI 확인을 위한 더미 데이터 예시 (실제 연동 시 제거)*
        model.addAttribute("customers", List.of(
                // 실제 DTO 구조에 맞춰 수정 필요
        ));

        // 활성화된 메뉴 표시를 위한 속성
        model.addAttribute("activeMenu", "customer");

        return "admin/customer"; // templates/admin/customer.html 반환
    }
}