// lib/features/auth/bloc/sign_in_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/auth_repository.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final AuthRepository _authRepository;

  SignInBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInTogglePassword>(_onTogglePassword);
    on<SignInSubmitted>(_onSubmitted);
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
      emit(state.copyWith(isSubmitting: false, didSucceed: true, formError: 'Succeed token="$token"'));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: 'Login failed\n'
        'username="${state.username}"\n'
        'password=${state.password}',
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
    } else {

      if (password.length < 6) {
        pErr = 'Password is invalid';
      }
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
