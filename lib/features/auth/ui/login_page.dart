import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/sign_up_page.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/widgets/auth_ui.dart';

import '../../../core/utils/ui_helpers.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول', isError: true);
      return;
    }

    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    showLocalizedSnackBar(
      context,
      message,
      durationSeconds: 4,
      forceError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

        if (state is AuthError) {
          final String msg = state.message.toLowerCase();
          final bool isSuccess =
              msg.contains('successfully') ||
              msg.contains('بنجاح') ||
              msg.contains('تم إرسال') ||
              msg.contains('تم تحديث') ||
              msg.contains('تم تسجيل');
          _showSnackBar(state.message, isError: !isSuccess);
        }
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        }
        if (state is AuthAuthenticated ||
            state is AuthUnauthenticated ||
            state is AuthError) {
          setState(() => _isLoading = false);
        }
      },
      child: AuthPageScaffold(
        appBarTitle: 'تسجيل الدخول',
        child: AuthFormCard(
          title: 'مرحباً بعودتك',
          subtitle: 'سجّل الدخول لمتابعة مزرعتك الذكية',
          children: <Widget>[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: AuthUi.inputDecoration(
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                icon: Icons.alternate_email_rounded,
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _handleLogin();
              },
              decoration: AuthUi.inputDecoration(
                label: 'كلمة المرور',
                hint: 'أدخل كلمة المرور',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: AuthUi.primaryButtonStyle,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Text('تسجيل الدخول'),
            ),
            const SizedBox(height: 8),
            AuthFooterLink(
              prompt: 'ليس لديك حساب؟',
              actionLabel: 'إنشاء حساب',
              enabled: !_isLoading,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<SignUpPage>(
                    builder: (BuildContext context) => const SignUpPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
