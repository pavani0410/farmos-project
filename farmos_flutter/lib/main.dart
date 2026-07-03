import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'app_shell.dart';

void main() {
  runApp(const FarmOSApp());
}

class FarmOSApp extends StatelessWidget {
  const FarmOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B4332),
          secondary: Color(0xFF52B788),
          surface: Colors.white,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
