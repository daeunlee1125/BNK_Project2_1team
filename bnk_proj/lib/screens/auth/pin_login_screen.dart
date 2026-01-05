import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_main/main.dart';
import '../../services/api_service.dart';
import '../main/bank_homepage.dart';
import '../app_colors.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class PinLoginScreen extends StatefulWidget {
  final String userId;
  final bool autoBioAuth;
  final bool isAuthMode; // true면 거래 인증용, false면 로그인용

  const PinLoginScreen({
    super.key,
    required this.userId,
    this.autoBioAuth = false, // 기본값 false
    this.isAuthMode = false, // 기본값은 로그인 모드
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _pin = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 자동 생체인증 옵션이 켜져있으면, 화면 빌드 후 지문 창 띄우기
    if (widget.autoBioAuth) {
      _authenticateBio();
    }
  }

  Future<void> _authenticateBio() async {
    bool authenticated = false;
    try {
      // 인증 시도 (시스템 팝업)
      authenticated = await auth.authenticate(
        localizedReason: '로그인하려면 지문 또는 Face ID로 인증해주세요.',

        // 생체 인증 문구
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: '생체 인증',
            cancelButton: '취소',
          ),
        ],

        options: const AuthenticationOptions(
          stickyAuth: true, // 앱이 잠깐 백그라운드 갔다 와도 인증창 유지
          biometricOnly: true, // PIN/패턴 말고 생체정보만 사용
        ),
      );
    } on PlatformException catch (e) {
      print("생체 인증 오류: $e");
      return;
    }

    if (!mounted) return;

    // 인증 성공 시 메인 화면으로 이동
    if (authenticated) {
      print("✅ 생체 인증 성공!");

      await _loginWithStoredPin();
    } else {
      print("❌ 생체 인증 실패 또는 취소됨 (PIN 입력 대기)");
    }
  }

  // 저장된 PIN으로 서버 로그인 (토큰 갱신용)
  Future<void> _loginWithStoredPin() async {
    setState(() => _isLoading = true);

    // 1. 저장소에서 저장해둔 PIN과 아이디 꺼내기
    const storage = FlutterSecureStorage();
    String? storedPin = await storage.read(key: 'user_pin');
    String? userId = widget.userId;

    if (storedPin == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("최초 1회는 간편비밀번호 입력이 필요합니다.")),
      );
      return;
    }

    // 2. 서버에 로그인 요청 (이 함수 안에서 토큰 저장(write)까지 수행됨)
    Map<String, dynamic> result = await ApiService.loginWithPin(userId, storedPin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'SUCCESS') {
      // 3. 토큰 갱신 성공 -> 이제 진짜 메인으로 이동
      if (widget.isAuthMode) {
        Navigator.pop(context, true); // 인증 모드면 true 반환
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BankHomePage()),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '생체 로그인 실패 (서버 오류)')),
      );
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

    // ★ PIN 검증 API 호출
    // (참고: 실제로는 loginWithPin 대신 verifyPin 같은 전용 API가 더 적합할 수 있음)
    Map<String, dynamic> result = await ApiService.loginWithPin(widget.userId, _pin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'SUCCESS') {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'user_pin', value: _pin);
      await storage.write(key: 'user_id', value: widget.userId); // 아이디도 같이 저장

      // 분기 처리
      if (widget.isAuthMode) {
        // 인증 모드라면: 성공 결과를 가지고 화면 닫기 (이전 화면으로 돌아감)
        Navigator.pop(context, true);
      } else {
        // 로그인 모드라면: 메인 화면으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BankHomePage()),
              (route) => false,
        );
      }
    } else {
      // 실패 처리 (기존 동일)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '인증번호가 일치하지 않습니다.'))
      );
      setState(() => _pin = "");
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