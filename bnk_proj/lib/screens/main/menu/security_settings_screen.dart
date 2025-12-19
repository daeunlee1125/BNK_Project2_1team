import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../../services/api_service.dart';
import '../../app_colors.dart';
import 'security_settings_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  bool _useBio = false; // 현재 설정 상태
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 초기 설정값 불러오기
  void _loadSettings() async {
    String? id = await _storage.read(key: 'saved_userid');
    // 실제로는 서버에서 'BIO_AUTH_YN' 값을 가져와야 정확하지만,
    // 편의상 로컬 스토리지에 저장된 값을 쓴다고 가정하거나 API를 호출합니다.
    String? bioYn = await _storage.read(key: 'use_bio'); // 'Y' or 'N'

    setState(() {
      _userId = id ?? "";
      _useBio = (bioYn == 'Y');
    });
  }

  // 스위치 토글 시 실행되는 함수
  void _toggleBio(bool value) async {
    if (value) {
      // 🟢 켜려고 할 때: 기기가 지문을 지원하는지 + 실제 지문 인식 테스트
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        _showMsg("이 기기는 생체 인식을 지원하지 않습니다.");
        return;
      }

      try {
        // 실제 지문 인증 시도 (본인 확인)
        bool didAuthenticate = await auth.authenticate(
          localizedReason: '생체 인증을 활성화하기 위해 본인 인증이 필요합니다.',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (didAuthenticate) {
          // 성공 시 서버 & 로컬에 저장
          _updateServer(true);
        }
      } catch (e) {
        _showMsg("인증 설정 중 오류가 발생했습니다.");
      }
    } else {
      // 🔴 끄려고 할 때: 그냥 끔
      _updateServer(false);
    }
  }

  // 서버 및 로컬에 상태 저장
  void _updateServer(bool isEnabled) async {
    // 1. 서버 전송
    await ApiService.toggleBioAuth(_userId, isEnabled);

    // 2. 로컬 저장 (로그인 화면에서 쓰기 위해)
    await _storage.write(key: 'use_bio', value: isEnabled ? 'Y' : 'N');

    setState(() {
      _useBio = isEnabled;
    });
    _showMsg(isEnabled ? "생체 인증이 활성화되었습니다." : "생체 인증이 해제되었습니다.");
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("인증/보안 설정")),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            title: const Text("간편 비밀번호 재설정"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: PIN 재설정 화면 이동 구현
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("지문/Face ID 사용"),
            subtitle: const Text("로그인 시 간편 비밀번호 대신 생체 정보를 사용합니다."),
            value: _useBio,
            activeColor: AppColors.pointDustyNavy,
            onChanged: _toggleBio, // 토글 함수 연결
          ),
          const Divider(),
        ],
      ),
    );
  }
}