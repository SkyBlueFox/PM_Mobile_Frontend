import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';

import 'sign_in_event.dart';
import 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  // ====== English, user-friendly, and safe messages ======
  static const String _msgEnterUsername = 'Please enter your email or username.';
  static const String _msgEnterPassword = 'Please enter your password.';
  static const String _msgInvalidCredentials = 'Invalid username or password.';
  static const String _msgNetwork = 'Unable to connect. Please check your internet or server and try again.';
  static const String _msgTimeout = 'Request timed out. Please try again.';
  static const String _msgUnexpected = 'Something went wrong. Please try again.';

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

    // If you removed Google sign-in from UI, you can also remove this handler + event.
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

    // Validate only "required fields" (avoid leaking password rules)
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

      _authBloc.add(AuthLoggedIn(token));

      // Optional security hygiene: clear password after success
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: true,
        formError: null,
        password: '',
        passwordTouched: false,
        passwordError: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: _friendlyErrorMessage(err), // <-- shows "Invalid username or password." on 401/403
      ));
    }
  }

  Future<void> _onGooglePressed(SignInGooglePressed e, Emitter<SignInState> emit) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(
      isSubmitting: true,
      formError: null,
      didSucceed: false,
    ));

    try {
      final token = await _authRepository.signInWithGoogle();
      _authBloc.add(AuthLoggedIn(token));
      emit(state.copyWith(isSubmitting: false, didSucceed: true));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: _friendlyErrorMessage(err),
      ));
    }
  }

  _ValidationResult _validate({required String username, required String password}) {
    String? uErr;
    String? pErr;

    if (username.trim().isEmpty) {
      uErr = _msgEnterUsername;
    }
    if (password.isEmpty) {
      pErr = _msgEnterPassword;
    }

    return _ValidationResult(
      isValid: uErr == null && pErr == null,
      usernameError: uErr,
      passwordError: pErr,
    );
  }

  String _friendlyErrorMessage(Object err) {
    // Timeout
    if (err is TimeoutException) return _msgTimeout;

    // Network
    if (err is SocketException) return _msgNetwork;

    // Status-code based mapping (preferred)
    final status = _tryReadStatusCode(err);

    // Credentials mismatch
    if (status == 401 || status == 403 || status == 400) return _msgInvalidCredentials;

    // Server errors
    if (status != null && status >= 500) return _msgNetwork;

    // Fallback by string (last resort)
    final s = err.toString().toLowerCase();
    if (s.contains('unauthorized') || s.contains('forbidden') || s.contains('401') || s.contains('403')) {
      return _msgInvalidCredentials;
    }
    if (s.contains('timeout')) return _msgTimeout;
    if (s.contains('socketexception') || s.contains('failed host lookup') || s.contains('connection refused')) {
      return _msgNetwork;
    }

    return _msgUnexpected;
  }

  int? _tryReadStatusCode(Object err) {
    // Supports many libs without hard dependency (dio/custom exception/etc.)
    try {
      final dynamic e = err;
      final dynamic sc = e.statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    try {
      final dynamic e = err;
      final dynamic sc = e.response?.statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    return null;
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
