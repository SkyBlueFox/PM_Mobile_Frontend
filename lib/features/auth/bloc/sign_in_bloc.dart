import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';

import 'sign_in_event.dart';
import 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  SignInBloc({
    required AuthRepository authRepository,
    required AuthBloc authBloc,
  })  : _authRepository = authRepository,
        _authBloc = authBloc,
        super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInTogglePassword>(_onTogglePassword);
    on<SignInSubmitted>(_onSubmitted);
    on<SignInGooglePressed>(_onGooglePressed);
  }

  void _onEmailChanged(SignInEmailChanged e, Emitter<SignInState> emit) {
    final v = _validate(username: e.value, password: state.password);
    emit(state.copyWith(
      username: e.value,
      usernameTouched: true,
      usernameError: v.usernameError,
      passwordError: v.passwordError,
      formError: null,

      // ไม่ต้องใช้เพื่อ navigate แล้ว (AuthGate ทำให้)
      didSucceed: false,
    ));
  }

  void _onPasswordChanged(SignInPasswordChanged e, Emitter<SignInState> emit) {
    final v = _validate(username: state.username, password: e.value);
    emit(state.copyWith(
      password: e.value,
      passwordTouched: true,
      usernameError: v.usernameError,
      passwordError: v.passwordError,
      formError: null,
      didSucceed: false,
    ));
  }

  void _onTogglePassword(SignInTogglePassword e, Emitter<SignInState> emit) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> _onSubmitted(SignInSubmitted e, Emitter<SignInState> emit) async {
    if (state.isSubmitting) return;

    final v = _validate(username: state.username, password: state.password);

    if (!v.isValid) {
      emit(state.copyWith(
        attemptedSubmit: true,
        usernameError: v.usernameError,
        passwordError: v.passwordError,
        formError: null,
        didSucceed: false,
      ));
      return;
    }

    emit(state.copyWith(
      attemptedSubmit: true,
      isSubmitting: true,
      formError: null,
      didSucceed: false,
    ));

    try {
      final token = await _authRepository.signIn(
        username: state.username.trim(),
        password: state.password,
      );

      // ✅ จุดสำคัญ: แจ้ง AuthBloc ว่า login แล้ว
      _authBloc.add(AuthLoggedIn(token));

      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: true, // optional: ไว้ debug/snackbar ได้
        formError: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: 'Login failed',
      ));
    }
  }

  Future<void> _onGooglePressed(
    SignInGooglePressed e,
    Emitter<SignInState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(
      isSubmitting: true,
      formError: null,
      didSucceed: false,
    ));

    try {
      final token = await _authRepository.signInWithGoogle(); // ✅ คุณจะเพิ่มเมธอดนี้ใน repo
      _authBloc.add(AuthLoggedIn(token));
      emit(state.copyWith(isSubmitting: false, didSucceed: true));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: 'Google sign-in failed',
      ));
    }
  }

  _ValidationResult _validate({required String username, required String password}) {
    String? uErr;
    String? pErr;

    if (username.trim().isEmpty) {
      uErr = 'Please enter email or username';
    }

    if (password.isEmpty) {
      pErr = 'Please enter password';
    } else if (password.length < 6) {
      pErr = 'Password is invalid';
    }

    final ok = (uErr == null) && (pErr == null);
    return _ValidationResult(isValid: ok, usernameError: uErr, passwordError: pErr);
  }
}

class _ValidationResult {
  final bool isValid;
  final String? usernameError;
  final String? passwordError;

  const _ValidationResult({
    required this.isValid,
    this.usernameError,
    this.passwordError,
  });
}