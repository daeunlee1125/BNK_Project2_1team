import 'package:flutter/material.dart';
import 'forex_insight.dart';
import '../../services/exchange_service.dart';
import 'exchange_complete_page.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:test_main/screens/auth/pin_login_screen.dart';
import 'package:test_main/screens/auth/pin_setup_screen.dart';
import '../../services/api_service.dart';


class ExchangeBuyPage extends StatefulWidget {
  final CurrencyRate rate;

  const ExchangeBuyPage({
    super.key,
    required this.rate,
  });

  @override
  State<ExchangeBuyPage> createState() => _ExchangeBuyPageState();
}


class _ExchangeBuyPageState extends State<ExchangeBuyPage> {
  String foreignAmount = "1";

  final LocalAuthentication auth = LocalAuthentication();

  int krwBalance = 0;
  bool isLoading = true;
  int foreignBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadMyAccounts();
  }

  // 통합 인증 및 환전 실행 로직 (사기)
  Future<void> _handleAuthAndBuy() async {
    // 0. 금액 검증
    if (foreignAmount.isEmpty || double.parse(foreignAmount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("구매할 금액을 입력해주세요.")),
      );
      return;
    }

    // ====================================================
    // [추가] 0.5. 약관 동의 여부 확인 (최초 1회)
    // ====================================================
    try {
      bool isAgreed = await ExchangeService.checkTermsAgreed();

      if (!isAgreed) {
        if (!mounted) return;
        // 동의가 안 되어 있다면 약관 팝업 띄우기
        bool? agreeResult = await _showTermsDialog();

        if (agreeResult == true) {
          // 동의했으면 서버에 저장하고 진행
          await ExchangeService.submitTermsAgreement();
        } else {
          // 동의 거부 시 중단
          return;
        }
      }
    } catch (e) {
      print("약관 확인 중 오류: $e");
      // 오류 발생 시 안전을 위해 진행 막거나, 스킵 정책에 따라 결정
      return;
    }

    // [1] 현재 로그인한 사용자 아이디 가져오기
    String? currentUserId = await ApiService.getSavedUserId();

    if (currentUserId == null) {
      // 아이디가 없으면(로그인 풀림 등) 에러 처리 후 종료
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 정보가 없습니다. 다시 로그인해주세요.")),
      );
      return;
    }

    // 1. PIN 등록 여부 확인
    bool hasPin = await ApiService.checkHasPin();

    if (!hasPin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("보안을 위해 간편비밀번호 설정이 필요합니다.")),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PinSetupScreen(userId: currentUserId)),
      );
      return;
    }

    // 2. 생체 인증 시도
    bool authenticated = false;
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        print("👆 생체 인증 시도..."); // [디버깅 추가]
        authenticated = await auth.authenticate(
          localizedReason: '환전을 진행하려면 인증해주세요.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        print("👆 생체 인증 결과: $authenticated"); // [디버깅 추가]
      }
    } catch (e) {
      print("❌ 생체 인증 에러: $e");
    }

    // 3. 생체 인증 실패 시 -> PIN 인증 화면으로 이동
    if (!authenticated) {
      if (!mounted) return;
      print("🔑 PIN 인증 화면 이동"); // [디버깅 추가]
      final bool? pinResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinLoginScreen(
            userId: currentUserId,
            isAuthMode: true,
          ),
        ),
      );

      if (pinResult != true) {
        print("❌ PIN 인증 실패 또는 취소"); // [디버깅 추가]
        return;
      }
    }

    // 4. 인증 성공 -> 환전 실행
    print("💰 인증 성공! 환전 실행 함수 호출"); // [디버깅 추가]
    await _executeBuy(); // await 추가 권장
  }

  // [추가] 실제 환전 API 호출 함수
  Future<void> _executeBuy() async {
    print("💸 _executeBuy 함수 진입"); // [디버깅 추가]
    try {
      final double foreign = double.tryParse(foreignAmount) ?? 0;
      final int krwAmount = (foreign * widget.rate.rate).round();

      print("📡 서버 환전 요청 시작: $foreign ${widget.rate.code}"); // [디버깅 추가]

      // 1️⃣ 서버 환전 요청
      await ExchangeService.buyForeignCurrency(
        toCurrency: widget.rate.code,
        krwAmount: krwAmount,
      );

      print("✅ 서버 환전 요청 성공!"); // [디버깅 추가]

      if (!mounted) return;

      // 2️⃣ 환전 완료 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExchangeCompletePage(
            currency: widget.rate.code,
            foreignAmount: foreign,
            krwAmount: krwAmount,
            appliedRate: widget.rate.rate,
          ),
        ),
      );

    } catch (e) {
      print("🔥 환전 처리 중 오류 발생: $e"); // [디버깅 추가]
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("환전 실패: $e")),
      );
    }
  }

  Future<void> _loadMyAccounts() async {
    try {
      final data = await ExchangeService.fetchMyExchangeAccounts(
        currency: widget.rate.code,
      );

      setState(() {
        krwBalance = (data['krwBalance'] as num?)?.toInt() ?? 0;
        foreignBalance = (data['frgnBalance'] as num?)?.toInt() ?? 0; // ✅ 추가
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("계좌 조회 실패: $e")),
      );
    }
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == "back") {
        if (foreignAmount.isNotEmpty) {
          foreignAmount =
              foreignAmount.substring(0, foreignAmount.length - 1);
          if (foreignAmount.isEmpty) foreignAmount = "0";
        }
        return;
      }

      // 🔹 소수점 처리
      if (value == ".") {
        // 이미 소수점이 있으면 무시
        if (foreignAmount.contains(".")) return;

        // "0" 또는 빈 값이면 "0."
        if (foreignAmount.isEmpty || foreignAmount == "0") {
          foreignAmount = "0.";
        } else {
          foreignAmount += ".";
        }
        return;
      }

      // 🔹 숫자 처리
      if (foreignAmount == "0") {
        foreignAmount = value;
      } else {
        foreignAmount += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double foreign = double.tryParse(foreignAmount) ?? 0;
    final int krwAmount = (foreign * widget.rate.rate).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FB),
      appBar: AppBar(
        title: Text("${widget.rate.code} 사기"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 환율 텍스트
          Text(
            "1 ${widget.rate.code} = ${widget.rate.rate.toStringAsFixed(2)}원",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 4),

          Text(
            '기준일: ${widget.rate.regDt}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black38,
            ),
          ),

          const SizedBox(height: 20),

          // 외화 카드
          _currencyCard(
            flag: widget.rate.flagEmoji,
            title: widget.rate.name,
            amount: "$foreignAmount ${widget.rate.code}",
            isActive: true,
            balance: "잔액 $foreignBalance ${widget.rate.code}",
          ),

          const SizedBox(height: 12),

          // 스왑 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                )
              ],
            ),
            child: const Icon(Icons.swap_vert),
          ),

          const SizedBox(height: 12),

          // KRW 카드
          _currencyCard(
            flag: "🇰🇷",
            title: "대한민국 원",
            amount: "$krwAmount KRW",
            isActive: false,
            balance: "잔액 ${krwBalance.toString()}원",
          ),

          const Spacer(),

          // 1. 키패드 표시
          _keypad(),

          const SizedBox(height: 16), // 간격 조절

          // 2. [추가] 법적 고지 문구 (Toss 스타일)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "확인을 누르면 환전 유의사항에 동의한 것으로 간주합니다.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54, // 기존 코드의 다른 텍스트와 통일감 있는 색상
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12), // 문구와 버튼 사이 간격

          // 3. 확인 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleAuthAndBuy, // 버튼 클릭 시 생체인증 로직 바로 실행
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F5073), // 기존 네이비 색상 유지
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "확인",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _currencyCard({
    required String flag,
    required String title,
    required String amount,
    required String balance,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                balance,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.blue : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // 약관 동의 다이얼로그
  Future<bool?> _showTermsDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 바깥 클릭해서 닫기 방지
      builder: (context) => AlertDialog(
        title: const Text("환전 서비스 약관 동의"),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text("비대면 외화 환전 서비스를 이용하기 위해 최초 1회 약관 동의가 필요합니다."),
              SizedBox(height: 10),
              Text(
                "제1조 (목적)\n본 약관은 고객이 모바일 앱을 통해 외화를 환전함에 있어...",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              // 필요한 약관 내용을 더 추가하세요
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 거부
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // 동의
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F5073),
            ),
            child: const Text("동의합니다", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    final keys = [
      "1","2","3",
      "4","5","6",
      "7","8","9",
      ".", "0", "back",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          return GestureDetector(
            onTap: () => _onKeyTap(key),
            child: Center(
              child: key == "back"
                  ? const Icon(Icons.backspace_outlined)
                  : Text(
                key,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}
