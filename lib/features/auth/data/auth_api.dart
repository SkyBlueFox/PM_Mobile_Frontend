import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_repository.dart';

class AuthApi {
  final String baseUrl;

  AuthApi({required this.baseUrl});

  Future<void> loginWithFirebase(String firebaseIdToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': firebaseIdToken,
      }),
    );
    if (response.statusCode == 401) {
      throw EmailNotWhitelistedException();
    }
    if (response.statusCode != 200) {
      throw Exception('Backend auth failed (${response.statusCode})');
    }
  }
}