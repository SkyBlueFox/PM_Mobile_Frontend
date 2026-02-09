import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exception ที่ "พก statusCode" เพื่อให้ชั้นบน (Bloc) map เป็นข้อความที่ถูกต้อง
class AuthApiException implements Exception {
  final int statusCode;
  final String message;

  const AuthApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}

class AuthApi {
  final String baseUrl;
  final http.Client _client;

  AuthApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// POST /api/auth/login
  /// - Success: return JSON map (ควรมี token)
  /// - Fail: throw AuthApiException พร้อม statusCode (สำคัญ)
  Future<Map<String, dynamic>> signIn(String username, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    // ตั้ง timeout เพื่อให้ Bloc แยก timeout ได้ (TimeoutException)
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));

    // ✅ ถ้าไม่ใช่ 2xx ให้ throw แบบมี statusCode
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // ไม่จำเป็นต้องส่งรายละเอียด server ไปให้ผู้ใช้
      throw AuthApiException(
        'Login failed.',
        statusCode: response.statusCode,
      );
    }

    // ✅ 2xx: parse JSON
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Response is not a JSON object');
    } catch (_) {
      // server ตอบรูปแบบไม่ถูกต้อง
      throw const AuthApiException(
        'Invalid server response.',
        statusCode: 500,
      );
    }
  }

  void dispose() => _client.close();
}
