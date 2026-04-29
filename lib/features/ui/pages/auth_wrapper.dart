import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/app_shell_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/bloc/auth_bloc.dart';
import 'package:smart_cucumber_agriculture_system/ui/bloc/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/login_page.dart';
import 'package:smart_cucumber_agriculture_system/core/config/app_access_control.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppAccessControl.instance.skipLogin,
      builder: (BuildContext context, bool skipLogin, Widget? child) {
        if (skipLogin) {
          return const AppShellPage();
        }

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (BuildContext context, AuthState state) {
            // 1. Authenticated or Error with user preserved -> Stay in App
            if (state is AuthAuthenticated ||
                (state is AuthError && state.authenticatedUser != null)) {
              return const AppShellPage();
            }

            // 2. Initial Loading Screen
            if (state is AuthInitial) {
              return _LoadingScreen();
            }

            // 3. Otherwise -> Login Flow
            // This includes AuthUnauthenticated and AuthError without user (signup/login errors)
            return const LoginPage();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.agriculture,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }
}
