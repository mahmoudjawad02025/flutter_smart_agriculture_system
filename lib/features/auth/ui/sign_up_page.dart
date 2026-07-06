import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/widgets/auth_ui.dart';

import '../../../core/utils/ui_helpers.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('كلمات المرور غير متطابقة');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل');
      return;
    }

    context.read<AuthCubit>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
  }

  void _showSnackBar(String message) {
    showLocalizedSnackBar(context, message, durationSeconds: 5);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (state is AuthError) {
          _showSnackBar(state.message);
        }
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        }
        if (state is AuthAuthenticated || state is AuthError) {
          setState(() => _isLoading = false);
          if (state is AuthAuthenticated) {
            Navigator.pop(context);
          }
        }
      },
      child: AuthPageScaffold(
        appBarTitle: 'إنشاء حساب',
        showBack: true,
        contentPadding: AuthUi.signUpContentPadding,
        child: AuthFormCard(
          title: 'إنشاء حساب',
          subtitle: 'انضم إلى نظام زراعة البندورة الذكي',
          children: <Widget>[
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: AuthUi.inputDecoration(
                label: 'الاسم الكامل',
                hint: 'أدخل اسمك',
                icon: Icons.person_outline_rounded,
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 14),
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
              textInputAction: TextInputAction.next,
              decoration: AuthUi.inputDecoration(
                label: 'كلمة المرور',
                hint: '6 أحرف على الأقل',
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
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _handleSignUp();
              },
              decoration: AuthUi.inputDecoration(
                label: 'تأكيد كلمة المرور',
                hint: 'أعد إدخال كلمة المرور',
                icon: Icons.verified_user_outlined,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isLoading ? null : _handleSignUp,
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
                  : const Text('إنشاء حساب'),
            ),
            const SizedBox(height: 8),
            AuthFooterLink(
              prompt: 'هل لديك حساب بالفعل؟',
              actionLabel: 'تسجيل الدخول',
              enabled: !_isLoading,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
