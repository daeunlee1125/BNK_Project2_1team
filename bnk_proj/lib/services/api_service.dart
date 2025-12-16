import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // 에뮬레이터에서 로컬호스트 접속 시 10.0.2.2 사용
  // 실기기 연결 시에는 내 PC의 IP 주소(예: 192.168.0.x)를 써야 함
  // 1. 실제 배포 주소 (앱 출시용 - 나중에 서버 올리면 그때 적으세요)
  static const String _prodUrl = "http://34.64.124.33:8080/backend/api/mobile";
  static const String baseUrl = "http://10.0.2.2:8080/backend/api/mobile";
  static const String base2Url = "http://192.168.0.209:8080/backend/api/mobile";
  static const _storage = FlutterSecureStorage();

  /// 로그인 요청
  static Future<Map<String, dynamic>> login(String userid, String password, String deviceId) async {
    final url = Uri.parse('$baseUrl/member/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userid": userid,
          "password": password,
          "deviceId": deviceId,
        }),
      );

      // 서버 응답 디코딩 (한글 깨짐 방지)
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // HTTP 200 OK (성공 or NEW_DEVICE 등 정상 응답)

        // 토큰이 있다면 저장 (SUCCESS일 때만 옴)
        if (responseBody['token'] != null) {
          await _storage.write(key: 'auth_token', value: responseBody['token']);
        }

        return responseBody; // 전체 데이터 반환 {"status": "...", "message": "..."}

      } else {
        // HTTP 401, 500 등 에러
        print("로그인 에러: ${response.body}");
        return {
          "status": "FAIL",
          "message": responseBody['message'] ?? "로그인 요청 실패"
        };
      }
    } catch (e) {
      print("서버 통신 오류: $e");
      return {"status": "ERROR", "message": "서버와 연결할 수 없습니다."};
    }
  }
}