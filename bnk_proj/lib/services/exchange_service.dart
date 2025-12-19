import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeService {
  static const String baseUrl = "http://34.64.124.33:8080/backend";

  /* =========================
     1. 환전 화면용 계좌 조회
     ========================= */
  static Future<Map<String, dynamic>> fetchMyExchangeAccounts({
    required String currency,
  }) async {
    final url =
    Uri.parse("$baseUrl/api/exchange/my-accounts?currency=$currency");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      // ✅ JWT 쿠키 자동 포함
    );

    if (response.statusCode != 200) {
      throw Exception("계좌 조회 실패: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  /* =========================
     2. 외화 매수 (환전)
     ========================= */
  static Future<void> buyForeignCurrency({
    required String toCurrency,
    required int krwAmount,
  }) async {
    final url = Uri.parse("$baseUrl/api/exchange/online");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
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
