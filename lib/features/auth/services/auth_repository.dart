import 'auth_api.dart';
import 'token_storage.dart';

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => 'AuthFailure: $message';
}

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _storage;

  AuthRepository({
    required AuthApi api,
    required TokenStorage storage,
  })  : _api = api,
        _storage = storage;

  /// สำเร็จจะ return token และเซฟลง secure storage แล้ว
  Future<String>  signIn({
    required String username,
    required String password,
  }) async {
    try {
      final token = await _api.signIn(
        username,password,
      );

      await _storage.saveAccessToken(token['token']);
      return token['token'];
    } on AuthApiException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw AuthFailure('Something went wrong. Please try again.');
    }
  }

  Future<String?> getSavedToken() => _storage.readAccessToken();

  Future<void> signOut() => _storage.clearAccessToken();
}
