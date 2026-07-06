import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

abstract final class AuthUi {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1F5B24);
  static const Color accent = Color(0xFF558B2F);
  static const Color surface = Color(0xFFF4F8EE);
  static const Color card = Colors.white;

  static BoxDecoration pageBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFE8F3E2), Color(0xFFF7FBF4), Color(0xFFEEF5E9)],
    ),
  );

  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FCF7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle primaryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primary,
    disabledBackgroundColor: Colors.grey.shade400,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    elevation: 0,
  );

  static const EdgeInsets loginContentPadding = EdgeInsets.fromLTRB(
    20,
    0,
    20,
    45,
  );
  static const EdgeInsets signUpContentPadding = EdgeInsets.fromLTRB(
    20,
    50,
    20,
    95,
  );
}

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.child,
    this.showBack = false,
    this.appBarTitle,
    this.contentPadding = AuthUi.loginContentPadding,
  });

  final Widget child;
  final bool showBack;
  final String? appBarTitle;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AuthUi.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Text(
          appBarTitle ?? AppStrings.appTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: AuthUi.pageBackgroundDecoration,
        child: Center(
          child: SingleChildScrollView(
            padding: contentPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AuthBrandingHeader(),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBrandingHeader extends StatelessWidget {
  const AuthBrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AuthUi.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              AppStrings.launcherIconAsset,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: AuthUi.surface,
                child: const Icon(
                  Icons.eco_rounded,
                  size: 48,
                  color: AuthUi.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.appTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AuthUi.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'الري التلقائي، التسميد، وكشف الأمراض بالذكاء الاصطناعي',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AuthUi.accent,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AuthUi.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AuthUi.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AuthUi.primaryDark,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    this.enabled = true,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(prompt, style: TextStyle(color: Colors.grey.shade600)),
        TextButton(
          onPressed: enabled ? onPressed : null,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AuthUi.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
