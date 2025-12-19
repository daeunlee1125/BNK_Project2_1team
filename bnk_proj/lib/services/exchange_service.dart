import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // ★ 이거 추가

class ExchangeService {
  static const String baseUrl = "http://34.64.124.33:8080/backend";

  /* =========================
     1. 환전 화면용 계좌 조회
     ========================= */
  static Future<Map<String, dynamic>> fetchMyExchangeAccounts({
    required String currency,
  }) async {
    final url =
    Uri.parse("$baseUrl/api/exchange/accounts?currency=$currency");

    // ✅ JWT 포함 헤더
    final headers = await ApiService.getAuthHeaders();

    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("계좌 조회 실패: ${response.body}");
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /* =========================
     2. 외화 매수 (환전)
     ========================= */
  static Future<void> buyForeignCurrency({
    required String toCurrency,
    required int krwAmount,
  }) async {
    final url = Uri.parse("$baseUrl/api/exchange/online");

    // ✅ JWT 포함 헤더
    final headers = await ApiService.getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "exchType": "B",
        "exchFromCurrency": "KRW",
        "exchToCurrency": toCurrency,
        "exchKrwAmount": krwAmount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("환전 실패: ${response.body}");
    }
  }
}
