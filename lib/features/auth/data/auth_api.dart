import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_repository.dart';

class AuthApi {
  final String baseUrl;

  AuthApi({required this.baseUrl});

  Future<void> loginWithFirebase(String firebaseIdToken) async {
    print('AuthApi: Logging in with Firebase ID token, length: ${firebaseIdToken}');
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $firebaseIdToken',
      },
      body: jsonEncode({
        'token': firebaseIdToken,
      }),
    );
    print('Auth API response: ${response.statusCode}, body: ${response.body}');
    // if (response.statusCode == 401) {
    //   throw EmailNotWhitelistedException();
    // }
    // if (response.statusCode != 200) {
    //   throw Exception('Backend auth failed (${response.statusCode})');
    // }
  }
}