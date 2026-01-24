import 'package:flutter_bloc/flutter_bloc.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

/// BLoC ของหน้า Sign in (Front-end เท่านั้น)
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    // กรอก Email/Username
    on<SignInEmailChanged>((e, emit) {
      emit(state.copyWith(
        emailOrUsername: e.value,
        isValid: _validate(emailOrUsername: e.value, password: state.password),
      ));
    });

    // กรอก Password
    on<SignInPasswordChanged>((e, emit) {
      emit(state.copyWith(
        password: e.value,
        isValid: _validate(emailOrUsername: state.emailOrUsername, password: e.value),
      ));
    });

    // Toggle โชว์/ซ่อน Password
    on<SignInTogglePassword>((_, emit) {
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
    });
  }

  // เงื่อนไขเปิดปุ่ม (ปรับได้)
  bool _validate({required String emailOrUsername, required String password}) {
    return emailOrUsername.trim().isNotEmpty && password.trim().length >= 6;
  }
}
