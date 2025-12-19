import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_main/services/api_service.dart';
import 'package:test_main/utils/device_manager.dart';
import '../main.dart'; // LoginPage가 있는 파일 import
import 'auth/pin_login_screen.dart'; // 핀 로그인 화면 import
import 'app_colors.dart'; // 색상 파일 import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // [핵심 로직] 저장된 아이디 확인 + 기기 검증 + 인증 방식 분기
  void _checkLoginStatus() async {
    // 1. 로딩 시간 확보
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. 저장된 정보 조회
    const storage = FlutterSecureStorage();
    String? savedId = await storage.read(key: 'saved_userid');
    String deviceId = await DeviceManager.getDeviceId();

    if (!mounted) return;

    if (savedId != null && savedId.isNotEmpty) {
      // [Case A] 저장된 아이디 있음 -> ★ 서버에 상태 확인 (Map으로 받음)
      Map<String, dynamic> result = await ApiService.checkDeviceStatus(savedId, deviceId);

      if (result['status'] == 'MATCH') {
        // ✅ 기기 일치! -> 상세 설정 확인
        bool useBio = result['useBio'] ?? false; // 생체인증 동의 여부
        bool hasPin = result['hasPin'] ?? false; // PIN 번호 설정 여부

        print("✅ 기기 검증 완료 (Bio: $useBio, PIN: $hasPin)");

        if (useBio) {
          // [경로 1] 생체인증 사용자 -> PIN 화면으로 가면서 자동 인증 실행
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinLoginScreen(
                userId: savedId,
                autoBioAuth: true, // ★ 중요: 들어가자마자 지문 팝업 띄우기
              ),
            ),
          );
        } else if (hasPin) {
          // [경로 2] PIN만 있는 사용자 -> PIN 입력 화면 대기
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinLoginScreen(
                userId: savedId,
                autoBioAuth: false,
              ),
            ),
          );
        } else {
          // [경로 3] 기기는 맞는데 인증수단(PIN/Bio)이 없음 -> 로그인 화면으로 보내서 설정 유도
          print("인증 수단 미설정 -> 로그인 화면 이동");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        // 기기 불일치
        print("기기 불일치 -> 정보 삭제");
        await storage.delete(key: 'saved_userid');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 정보가 변경되어 다시 로그인이 필요합니다.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // [Case B] 저장된 아이디 없음 -> 로그인 화면
      print("저장된 정보 없음 -> 로그인 화면 이동");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 계산 (비율로 배치하기 위함)
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // ★ pubspec.yaml의 color와 일치필수!
      body: Stack(
        children: [
          // 1. 로고를 화면 정중앙에 배치 (네이티브 스플래시와 위치 일치)
          Center(
            child: Image.asset(
              'images/icon.png',
              width: 120, // 네이티브 스플래시 이미지 크기와 비슷하게 조절
            ),
          ),

          // 2. 텍스트와 로딩바는 로고 아래쪽에 배치
          Positioned(
            bottom: screenHeight * 0.15, // 화면 하단에서 15% 위치
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "FLOBANK",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.pointDustyNavy),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(color: AppColors.pointDustyNavy),
              ],
            ),
          ),
        ],
      ),
    );
  }
}