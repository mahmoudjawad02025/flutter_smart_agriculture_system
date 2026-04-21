import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/app_shell/ui/app_shell_page.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/login_page.dart';

import '../../../core/config/app_access_control.dart';

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
            if (state is AuthInitial || state is AuthLoading) {
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is AuthAuthenticated) {
              return const AppShellPage();
            } else if (state is AuthUnauthenticated) {
              return const LoginPage();
            } else if (state is AuthError) {
              return Scaffold(
                backgroundColor: const Color(0xFFEEF5E9),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Auth Error',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(state.message),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                        },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}
