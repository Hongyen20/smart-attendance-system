import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AttendGoApp());
}

class AttendGoApp extends StatelessWidget {
  const AttendGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const LoginScreen(),
    );
  }
}
