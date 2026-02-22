import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/sign_in_bloc.dart';
import '../../bloc/sign_in_event.dart';
import '../../bloc/sign_in_state.dart';

import '../../data/auth_repository.dart';
import '../../bloc/auth_bloc.dart';

import '../widgets/auth_background.dart';
import '../widgets/pill_text_field.dart';


class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const Color _blue = Color(0xFF3AA7FF);
  static const Color _red = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SignInBloc(
        authRepository: ctx.read<AuthRepository>(), // ✅ ใช้ repo จาก main.dart
        authBloc: ctx.read<AuthBloc>(),             // ✅ ส่งให้ bloc เพื่อ dispatch AuthLoggedIn
      ),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (p, c) => p.didSucceed != c.didSucceed,
      listener: (context, st) {
        if (st.didSucceed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in')),
          );
        }
      },
      child: Scaffold(
        body: AuthBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: BlocBuilder<SignInBloc, SignInState>(
                    buildWhen: (p, c) =>
                        p.isSubmitting != c.isSubmitting ||
                        p.formError != c.formError,
                    builder: (context, st) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          const Text(
                            'Name',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: SignInPage._blue,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Let’s Sign in",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: SignInPage._blue,
                            ),
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                                  backgroundColor: Colors.white,
                                ),
                                onPressed: st.isSubmitting
                                    ? null
                                    : () => context
                                        .read<SignInBloc>()
                                        .add(const SignInGooglePressed()),
                                child: st.isSubmitting
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.g_mobiledata_rounded,
                                            size: 28,
                                            color: Colors.black87,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          if (st.formError != null &&
                              st.formError!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              st.formError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}