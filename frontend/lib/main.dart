import 'package:flutter/material.dart';
import 'screens/employee_home_screen.dart';

void main() {
  runApp(const FlexTimeApp());
}

class FlexTimeApp extends StatelessWidget {
  const FlexTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const EmployeeHomeScreen(),
    );
  }
}
