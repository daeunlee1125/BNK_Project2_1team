import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/terms.dart';

class TermsService {
  static const String baseUrl = 'http://34.64.124.33:8080/backend';
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<TermsDocument>> fetchTerms({int status = 4}) async {
    final token = await _storage.read(key: 'auth_token');

    final url = '$baseUrl/deposit/terms?status=$status';

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode != 200) {
      throw Exception('약관 정보를 불러오지 못했습니다.');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    return data
        .map((e) => TermsDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
