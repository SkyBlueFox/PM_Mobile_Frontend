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

  static const String _msgNetwork =
      'Unable to connect. Please check your internet or server and try again.';
  static const String _msgTimeout =
      'Request timed out. Please try again.';
  static const String _msgUnexpected =
      'Something went wrong. Please try again.';

  SignInBloc({
    required AuthRepository authRepository,
    required AuthBloc authBloc,
  })  : _authRepository = authRepository,
        _authBloc = authBloc,
        super(const SignInState()) {

    on<SignInGooglePressed>(_onGooglePressed);
  }

  Future<void> _onGooglePressed(
    SignInGooglePressed event,
    Emitter<SignInState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(
      isSubmitting: true,
      formError: null,
      didSucceed: false,
    ));

    try {
      final backendToken = await _authRepository.signInWithGoogle();

      _authBloc.add(AuthLoggedIn(backendToken));

      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        isSubmitting: false,
        didSucceed: false,
        formError: _friendlyErrorMessage(err),
      ));
    }
  }

  String _friendlyErrorMessage(Object err) {
    if (err is TimeoutException) return _msgTimeout;
    if (err is SocketException) return _msgNetwork;

    final s = err.toString().toLowerCase();

    if (s.contains('network') ||
        s.contains('socket') ||
        s.contains('failed host lookup')) {
      return _msgNetwork;
    }

    if (s.contains('timeout')) {
      return _msgTimeout;
    }

    return _msgUnexpected;
  }
}