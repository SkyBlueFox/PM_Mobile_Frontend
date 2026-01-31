import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc({required AuthRepository repo})
      : _repo = repo,
        super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final saved = await _repo.getSavedToken();
      if (saved != null && saved.trim().isNotEmpty) {
        emit(AuthAuthenticated(saved));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      // ถ้าอ่าน storage พัง ก็ถือว่าไม่ login
      emit(const AuthUnauthenticated());
    }
  }

  void _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(event.token));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repo.signOut(); // clear token
    } catch (_) {
      // ถึงลบไม่สำเร็จก็ให้ถือว่าออกจากระบบไว้ก่อนเพื่อ UX
    }
    emit(const AuthUnauthenticated());
  }
}
