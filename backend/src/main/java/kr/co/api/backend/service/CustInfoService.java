package kr.co.api.backend.service;

import kr.co.api.backend.dto.CustInfoDTO;
import kr.co.api.backend.jwt.JwtTokenProvider;
import kr.co.api.backend.mapper.MemberMapper;
import kr.co.api.backend.util.AesUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustInfoService {
    private final PasswordEncoder passwordEncoder; // SecurityConfig에서 등록한 빈
    private final JwtTokenProvider jwtTokenProvider;
    private final MemberMapper memberMapper;

    public void saveLastLogin(String custId) {
        memberMapper.insertLastLogin(custId);
    }

    /*
      회원가입 처리
     */
    public void register(CustInfoDTO custInfoDTO) {

        log.info("[회원가입 요청] DTO 전송: {}", custInfoDTO.getCustId());

        // 비밀번호 암호화 => 단방향
        String endPw = passwordEncoder.encode(custInfoDTO.getCustPw());
        custInfoDTO.setCustPw(endPw);

        // 주민번호, 전화번호, 생년월일, 이메일 암호화 (encrypt : 암호화, decrypt : 복호화)
        String aesJumin = AesUtil.encrypt(custInfoDTO.getCustJumin());
        String aesHp = AesUtil.encrypt(custInfoDTO.getCustHp());
        String aesEmail = AesUtil.encrypt(custInfoDTO.getCustEmail());

        custInfoDTO.setCustJumin(aesJumin);
        custInfoDTO.setCustHp(aesHp);
        custInfoDTO.setCustEmail(aesEmail);

        memberMapper.registerCustInfo(custInfoDTO);
    }

    public String apiRegister(CustInfoDTO custInfoDTO) {

        log.info("[회원가입 요청] DTO 전송: {}", custInfoDTO.getCustId());

        // 비밀번호 암호화 => 단방향
        String endPw = passwordEncoder.encode(custInfoDTO.getCustPw());
        custInfoDTO.setCustPw(endPw);
        
        char genderCode = custInfoDTO.getCustJumin().charAt(6);
        
        // 주민번호에서 성별 추출
        switch (genderCode) {
            case '1': case '3': case '5': case '7':
                custInfoDTO.setCustGen("M");
                break;
            case '2': case '4': case '6': case '8':
                custInfoDTO.setCustGen("F");
                break;
            default:
                throw new IllegalArgumentException("잘못된 주민번호 성별 코드");
        }

        // 주민번호에서 생년월일 추출
        String yy = custInfoDTO.getCustJumin().substring(0, 2);
        String mm = custInfoDTO.getCustJumin().substring(2, 4);
        String dd = custInfoDTO.getCustJumin().substring(4, 6);
        int century = 2000;
        switch (genderCode) {
            case '1':
            case '2':
            case '5':
            case '6':
                century = 1900;
                break;
            default:
                break;
        }
        int year = century + Integer.parseInt(yy);
        custInfoDTO.setCustBirthDt(LocalDate.of(
                year,
                Integer.parseInt(mm),
                Integer.parseInt(dd)
        ));


        // 주민번호, 전화번호, 생년월일, 이메일 암호화 (encrypt : 암호화, decrypt : 복호화)
        String aesJumin = AesUtil.encrypt(custInfoDTO.getCustJumin());
        String aesHp = AesUtil.encrypt(custInfoDTO.getCustHp());
        String aesEmail = AesUtil.encrypt(custInfoDTO.getCustEmail());

        custInfoDTO.setCustJumin(aesJumin);
        custInfoDTO.setCustHp(aesHp);
        custInfoDTO.setCustEmail(aesEmail);

        memberMapper.apiRegister(custInfoDTO);

        return memberMapper.findByIdCustInfo(custInfoDTO.getCustId()).getCustCode();
    }

    /*
        회원가입 - 아이디 유효성 검사
     */
    public Boolean checkId(String custId) {
        CustInfoDTO dto = memberMapper.findByIdCustInfo(custId);
        if(dto != null){
            return true; // 아이디 이미 존재
        }else {
            return false; // 아이디 없음
        }
    }

    /*
    로그인 처리
     */
    public CustInfoDTO login(String custId, String rawPassword) {
        CustInfoDTO custInfoDTO = memberMapper.findByIdCustInfo(custId); // DB에서 ID 있는지 확인

        if(custInfoDTO == null){ // 없으면
            log.info("로그인 실패: 존재하지 않는 아이디 - {}", custId);
            return null;
        }

        // matches(평문, 암호문) 메서드 사용
        if(!passwordEncoder.matches(rawPassword, custInfoDTO.getCustPw())){ // 있으면 비밀번호 확인

            log.warn("로그인 실패: 비밀번호 불일치 - {}", custId);
            return null; // 컨트롤러에서 로그인 실패 처리
        }

        custInfoDTO.setCustPw(null); // 보안상 비밀번호를 null로 보냄. 알 필요 없음.
        // 인증 성공
        return custInfoDTO;
    }


}
