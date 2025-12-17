import 'package:flutter/material.dart';
import 'package:test_main/screens/app_colors.dart';
import 'package:test_main/screens/main/bank_homepage.dart';
import 'package:test_main/services/api_service.dart';
import 'package:test_main/utils/device_manager.dart';

class AuthVerificationScreen extends StatefulWidget {
  final String userId;
  final String userPassword;

  const AuthVerificationScreen({
    super.key,
    required this.userId,
    required this.userPassword,
  });

  @override
  State<AuthVerificationScreen> createState() => _AuthVerificationScreenState();
}

class _AuthVerificationScreenState extends State<AuthVerificationScreen> {
  // 전화번호 입력 컨트롤러 삭제됨 (보안 강화)
  final TextEditingController _codeController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String _maskedPhone = ""; // 서버에서 받아올 마스킹된 번호

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // 1. 내 정보에 등록된 번호로 인증번호 요청
  void _requestAuthCode() async {
    setState(() => _isLoading = true);

    // API 호출 (ID만 보냄)
    Map<String, dynamic> result = await ApiService.sendAuthCodeToMember(widget.userId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['status'] == 'SUCCESS') {
        _isCodeSent = true;
        _maskedPhone = result['maskedPhone'] ?? "등록된 번호";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_maskedPhone 로 인증번호가 발송되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '발송 실패')),
        );
      }
    });
  }

  // 2. 인증번호 확인 및 기기 등록
  void _verifyAndRegister() async {
    String inputCode = _codeController.text.trim();
    if (inputCode.isEmpty) return;

    setState(() => _isLoading = true);

    // [Step A] 인증번호 검증 (서버)
    bool isVerified = await ApiService.verifyAuthCode(widget.userId, inputCode);

    if (isVerified) {
      // [Step B] 기기 등록 진행
      String deviceId = await DeviceManager.getDeviceId();
      bool registerSuccess = await ApiService.registerDevice(
          widget.userId,
          widget.userPassword,
          deviceId
      );

      if (!mounted) return;

      if (registerSuccess) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BankHomePage()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 등록 완료! 환영합니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 등록 실패. 잠시 후 다시 시도해주세요.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호가 올바르지 않습니다.')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 인증')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '회원정보에 등록된 휴대전화로\n인증번호를 발송합니다.',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pointDustyNavy,
                    height: 1.4
                ),
              ),
              const SizedBox(height: 30),

              // 인증 박스
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7EBF3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isCodeSent) ...[
                      const Text("본인 확인을 위해 인증번호를 요청해주세요.", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _requestAuthCode,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.pointDustyNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('인증번호 요청하기', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // 인증번호 발송 후 화면
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("받는 사람: $_maskedPhone", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                              onPressed: _requestAuthCode,
                              child: const Text("재전송")
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '인증번호 6자리 입력',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          suffixIcon: Icon(Icons.timer, size: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _verifyAndRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.pointDustyNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('인증 확인', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}