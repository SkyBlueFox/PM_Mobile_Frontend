import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';

import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/token_storage.dart';

import 'features/auth/ui/sign_in_page.dart';
import 'features/home/ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // สีหลัก
  static const Color _blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    // สร้าง dependency "ครั้งเดียว"
    final api = AuthApi(
      baseUrl: dotenv.get('BACKEND_API_URL'),
    );
    final repo = AuthRepository(
      api: api,
      storage: const TokenStorage(),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: repo),
      ],
      child: BlocProvider<AuthBloc>(
        create: (ctx) => AuthBloc(repo: ctx.read<AuthRepository>())..add(const AuthStarted()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Auth UI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: _blue),
            scaffoldBackgroundColor: Colors.white,

            // cursor/selection
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: _blue,
              selectionColor: Color(0x553AA7FF),
              selectionHandleColor: _blue,
            ),

            // สไตล์ TextField
            inputDecorationTheme: const InputDecorationTheme(
              hintStyle: TextStyle(color: Color(0xFF7A7A7A)),
            ),
          ),

          // ✅ gate ตัดสินใจไปหน้าไหน
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, st) {
        if (st is AuthAuthenticated) {
          return const HomePage();
        }
        if (st is AuthUnauthenticated) {
          return const SignInPage();
        }
        // Unknown/loading  
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
