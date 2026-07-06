import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/app_shell/ui/app_shell_page.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/login_page.dart';

import '../../../core/config/app_access_control.dart';
import '../../../core/localization/app_strings.dart';

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

            // 2. Loading states
            if (state is AuthInitial || state is AuthLoading) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFE8F3E2),
              Color(0xFFF7FBF4),
              Color(0xFFEEF5E9),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  AppStrings.launcherIconAsset,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل التطبيق...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
