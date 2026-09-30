import 'package:flutter/material.dart';

import '../services/auth_state.dart';

import 'login_screen.dart';
import 'employee_home_screen.dart';
import 'admin_home_screen.dart';
import 'super_admin_home_screen.dart';

// AUTH GATE
// Màn hình khởi động của app

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _restoreFuture;

  @override
  void initState() {
    super.initState();

    _restoreFuture = AuthState.instance.restore();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoreFuture,

      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashView();
        }

        final restored = snapshot.data == true;

        if (!restored) {
          return const LoginScreen();
        }

        switch (AuthState.instance.role) {
          case 'SuperAdmin':
            return const SuperAdminHomeScreen();

          case 'Admin':
            return const AdminHomeScreen();

          case 'Employee':
          default:
            return const EmployeeHomeScreen();
        }
      },
    );
  }
}

// SPLASH

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 220,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 26,
              height: 26,

              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Color(0xFF2864E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
