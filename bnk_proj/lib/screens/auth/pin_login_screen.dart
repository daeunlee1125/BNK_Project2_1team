import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_main/main.dart';
import '../../services/api_service.dart';
import '../main/bank_homepage.dart';
import '../app_colors.dart';
import 'package:local_auth/local_auth.dart';

class PinLoginScreen extends StatefulWidget {
  final String userId;
  final bool autoBioAuth;
  const PinLoginScreen({
    super.key,
    required this.userId,
    this.autoBioAuth = false // 기본값 false
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final LocalAuthentication auth = LocalAuthentication(); // ★ 인증 객체 생성
  String _pin = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ★ 자동 생체인증 옵션이 켜져있으면, 화면 빌드 후 지문 창 띄우기
    if (widget.autoBioAuth) {
      _authenticateBio();
    }
  }

  Future<void> _authenticateBio() async {
    bool authenticated = false;
    try {
      // 1. 기기가 생체인증을 지원하는지 확인 (선택 사항)
      // bool canCheckBiometrics = await auth.canCheckBiometrics;

      // 2. 인증 시도 (시스템 팝업)
      authenticated = await auth.authenticate(
        localizedReason: '로그인하려면 지문 또는 Face ID로 인증해주세요.',
        options: const AuthenticationOptions(
          stickyAuth: true, // 앱이 잠깐 백그라운드 갔다 와도 인증창 유지
          biometricOnly: true, // PIN/패턴 말고 생체정보만 사용
        ),
      );
    } on PlatformException catch (e) {
      print("생체 인증 오류: $e");
      // 오류 나면 그냥 조용히 PIN 입력 모드로 둠
      return;
    }

    if (!mounted) return;

    // 3. 인증 성공 시 메인 화면으로 이동
    if (authenticated) {
      print("✅ 생체 인증 성공! 메인으로 이동합니다.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BankHomePage()),
            (route) => false,
      );
    } else {
      print("❌ 생체 인증 실패 또는 취소됨 (PIN 입력 대기)");
    }
  }

  // 번호 입력 (이름을 _onKeyTap으로 통일)
  void _onKeyTap(String value) {
    if (_pin.length < 6) {
      setState(() => _pin += value);
    }
    if (_pin.length == 6) {
      _verifyPin(); // 6자리 입력 시 즉시 검증
    }
  }

  // 삭제 로직 추가
  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  // 최종 검증 및 로그인
  void _verifyPin() async {
    setState(() => _isLoading = true);

    // ★ 백엔드 API 호출: PIN 전용 로그인
    Map<String, dynamic> result = await ApiService.loginWithPin(widget.userId, _pin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'SUCCESS') {
      // 로그인 성공 시 메인으로 이동 (이전 기록 삭제)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BankHomePage()), // LoginPage로 직접 이동
            (route) => false,
      );
    } else {
      // 실패 시 알림 및 초기화
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '인증번호가 일치하지 않습니다.'))
      );
      setState(() => _pin = ""); // 입력창 초기화
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("간편로그인")),
      body: Column(
        children: [
          const SizedBox(height: 60),
          const SizedBox(height: 8),
          const Text("간편비밀번호 6자리를 입력하세요", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),

          // 다른 계정으로 로그인 버튼
          TextButton(
            onPressed: () async {
              // 저장된 아이디 삭제
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'saved_userid');

              // 로그인 화면으로 이동
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

              // 또는 직접 이동: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: const Text("다른 아이디로 로그인", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
          ),

          // PIN 도트 UI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16, height: 16,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? AppColors.pointDustyNavy : Colors.grey[300]
              ),
            )),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
          // 지문 인증 수동 호출 버튼
          if (widget.autoBioAuth && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TextButton.icon(
                onPressed: _authenticateBio, // 함수 다시 호출
                icon: const Icon(Icons.fingerprint, size: 24, color: AppColors.pointDustyNavy),
                label: const Text("지문 인증 다시 시도", style: TextStyle(color: AppColors.pointDustyNavy)),
              ),
            ),

          const Spacer(),
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    List<String> keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "back"];
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      color: Colors.grey[50],
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          String key = keys[index];
          if (key == "") return const SizedBox();
          if (key == "back") {
            return IconButton(onPressed: _onBackspace, icon: const Icon(Icons.backspace_outlined));
          }
          return InkWell(
            onTap: () => _onKeyTap(key),
            child: Center(
              child: Text(key, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}