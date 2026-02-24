import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pm_mobile_frontend/features/home/data/widget_repository.dart';

import 'data/device_repository.dart';
import 'data/room_repository.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';

import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/token_storage.dart';

import 'features/auth/ui/pages/sign_in_page.dart';
import 'features/home/ui/pages/home_page.dart';

import 'features/home/bloc/devices_bloc.dart';
import 'features/home/bloc/devices_event.dart';

import 'features/room/bloc/rooms_bloc.dart';
import 'features/room/bloc/rooms_event.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    final baseUrl = dotenv.get('BACKEND_API_URL');

    // auth deps (create once)
    final api = AuthApi(baseUrl: baseUrl);
    final authRepo = AuthRepository(
      api: api,
      storage: const TokenStorage(),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepo),

        // ✅ app-wide repos (create once)
        RepositoryProvider<WidgetRepository>(
          create: (_) => WidgetRepository(baseUrl: baseUrl),
        ),
        RepositoryProvider<RoomRepository>(
          create: (_) => RoomRepository(baseUrl: baseUrl),
        ),
        RepositoryProvider<DeviceRepository>(
          create: (_) => DeviceRepository(baseUrl: baseUrl),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // ✅ Auth gate
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(repo: ctx.read<AuthRepository>())
              ..add(const AuthStarted()),
          ),

          // ✅ RoomsBloc available globally
          BlocProvider<RoomsBloc>(
            create: (ctx) => RoomsBloc(
              roomRepo: ctx.read<RoomRepository>(),
            )..add(const RoomsStarted()),
          ),

          // ✅ DevicesBloc available globally
          BlocProvider<DevicesBloc>(
            create: (ctx) => DevicesBloc(
              widgetRepo: ctx.read<WidgetRepository>(),
              roomRepo: ctx.read<RoomRepository>(),
              deviceRepo: ctx.read<DeviceRepository>(),
            )
              ..add(const DevicesStarted())
              ..add(const WidgetsPollingStarted(
                roomId: 1,
                interval: Duration(seconds: 5),
              )),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Auth UI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: _blue),
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.dmSansTextTheme(),
            primaryTextTheme: GoogleFonts.dmSansTextTheme(),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: _blue,
              selectionColor: Color(0x553AA7FF),
              selectionHandleColor: _blue,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              hintStyle: TextStyle(color: Color(0xFF7A7A7A)),
            ),
          ),
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const SignInPage();
      },
    );
  }
}