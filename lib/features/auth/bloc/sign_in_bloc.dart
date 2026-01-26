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
    emit(state.copyWith(
      username: e.value,
      isValid: _validate(username: e.value, password: state.password),
      errorMessage: null,
      didSucceed: false,
    ));
  }

  void _onPasswordChanged(SignInPasswordChanged e, Emitter<SignInState> emit) {
    emit(state.copyWith(
      password: e.value,
      isValid: _validate(username: state.username, password: e.value),
      errorMessage: null,
      didSucceed: false,
    ));
  }

  void _onTogglePassword(SignInTogglePassword e, Emitter<SignInState> emit) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> _onSubmitted(SignInSubmitted e, Emitter<SignInState> emit) async {
    if (!state.isValid || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null, didSucceed: false));

    try {
      // repo จะ call API + save token ใน secure storage ให้แล้ว
      await _authRepository.signIn(
        username: state.username.trim(),
        password: state.password,
      );

      emit(state.copyWith(isSubmitting: false, didSucceed: true));
    } catch (err) {
      // ถ้าใช้ AuthFailure ตามที่ให้ไว้ จะมี message
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: err.toString(),
        didSucceed: false,
      ));
    }
  }

  bool _validate({required String username, required String password}) {
    return username.trim().isNotEmpty && password.trim().length >= 6;
  }
}
