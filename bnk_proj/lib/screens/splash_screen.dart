import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_main/services/api_service.dart';
import 'package:test_main/utils/device_manager.dart';
import '../main.dart'; // LoginPage가 있는 파일 import
import 'auth/pin_login_screen.dart'; // 핀 로그인 화면 import
import 'auth/pin_setup_screen.dart';
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

  // [핵심 로직] 저장된 아이디 확인 + 기기 검증 + 상태별 분기
  void _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    const storage = FlutterSecureStorage();
    String? savedId = await storage.read(key: 'saved_userid');
    String deviceId = await DeviceManager.getDeviceId();

    if (!mounted) return;

    if (savedId != null && savedId.isNotEmpty) {
      // 1. 서버 검증
      Map<String, dynamic> result = await ApiService.checkDeviceStatus(savedId, deviceId);

      if (result['status'] == 'MATCH') {
        bool useBio = result['useBio'] ?? false; // 생체 사용 동의 여부
        bool hasPin = result['hasPin'] ?? false; // PIN 설정 여부

        print("✅ 기기 검증 완료 (Bio: $useBio, PIN: $hasPin)");

        // ★ [수정된 로직] PIN 존재 여부를 가장 먼저 확인!
        if (!hasPin) {
          // Case 1: PIN이 없음 -> 생체고 뭐고 무조건 설정 화면으로 납치
          print("⚠️ PIN 미설정 -> 설정 화면 이동");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보안을 위해 간편 비밀번호 설정이 필요합니다.')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinSetupScreen(userId: savedId),
            ),
          );
        }
        else {
          // Case 2: PIN이 있음 -> 로그인 화면 이동
          // (생체 사용자는 autoBioAuth를 켜서 보냄)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PinLoginScreen(
                userId: savedId,
                autoBioAuth: useBio, // true면 들어가자마자 지문 뜸, false면 PIN 입력만
              ),
            ),
          );
        }

      } else {
        // 기기 불일치
        print("⛔ 기기 불일치");
        await storage.delete(key: 'saved_userid');
        if(!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 정보가 변경되어 다시 로그인이 필요합니다.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // 저장된 아이디 없음
      print("ℹ️ 저장된 정보 없음");
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