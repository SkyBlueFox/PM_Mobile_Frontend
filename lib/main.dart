import 'package:flutter/material.dart';
import 'features/auth/sign_in_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // สีหลักตาม mock
  static const Color _blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth UI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
        scaffoldBackgroundColor: Colors.white,

        // ให้ cursor/selection เป็นโทนน้ำเงินเหมือน UI
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _blue,
          selectionColor: Color(0x553AA7FF),
          selectionHandleColor: _blue,
        ),

        // สไตล์ TextField ให้ดูเนียนขึ้น
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Color(0xFF7A7A7A)),
        ),
      ),

      // หน้าแรก
      home: const SignInPage(),
    );
  }
}
