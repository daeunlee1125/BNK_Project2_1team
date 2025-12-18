// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

    // 2. 보안 저장소에서 아이디 조회
    const storage = FlutterSecureStorage();
    String? savedId = await storage.read(key: 'saved_userid');

    if (!mounted) return;

    if (savedId != null && savedId.isNotEmpty) {
      // [Case A] 저장된 아이디 있음 -> 간편 로그인(PIN) 화면으로 이동
      print("✅ 저장된 아이디 발견: $savedId -> PIN 로그인 화면으로 이동");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PinLoginScreen(userId: savedId)),
      );
    } else {
      // [Case B] 저장된 아이디 없음 -> 일반 로그인 화면으로 이동
      print("ℹ️ 저장된 정보 없음 -> 일반 로그인 화면으로 이동");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 또는 AppColors.mainPaleBlue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 이미지 (assets에 있다면 Image.asset 사용)
            // Image.asset('assets/images/logo.png', width: 120),

            // 로고가 없다면 임시 아이콘
            Icon(Icons.lock_person_rounded, size: 80, color: AppColors.pointDustyNavy),
            const SizedBox(height: 20),

            const Text(
              "FLOBANK",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.pointDustyNavy),
            ),
            const SizedBox(height: 30),

            // 로딩 인디케이터
            const CircularProgressIndicator(color: AppColors.pointDustyNavy),
          ],
        ),
      ),
    );
  }
}