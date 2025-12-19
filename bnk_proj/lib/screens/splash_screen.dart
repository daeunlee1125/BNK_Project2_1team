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

  // [핵심 로직] 저장된 아이디가 있는지 확인하고 화면 이동
  void _checkLoginStatus() async {
    // 1. 아주 잠깐 대기 (로고 보여줄 시간 & 스토리지 로딩 시간 확보)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. 필요한 정보 조회 (저장된 ID, 현재 기기 ID)
    const storage = FlutterSecureStorage();
    String? savedId = await storage.read(key: 'saved_userid');
    String deviceId = await DeviceManager.getDeviceId();

    if (!mounted) return;

    if (savedId != null && savedId.isNotEmpty) {
      // [Case A] 저장된 아이디가 있음 -> ★ 서버에 기기 일치 여부 확인
      bool isMatch = await ApiService.checkDeviceMatch(savedId, deviceId);

      if (isMatch) {
        // 기기 검증 성공 -> 간편 로그인(PIN) 화면으로
        print("기기 검증 완료: $savedId -> PIN 화면 이동");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PinLoginScreen(userId: savedId)),
        );
      } else {
        // 기기 불일치 (다른 폰에서 복사해왔거나 정보가 변경됨)
        print("기기 정보 불일치 -> 정보 삭제 후 로그인 화면 이동");
        await storage.delete(key: 'saved_userid'); // 보안을 위해 잘못된 정보 삭제

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 정보가 변경되어 다시 로그인이 필요합니다.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // [Case B] 저장된 아이디 없음 -> 일반 로그인 화면으로
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