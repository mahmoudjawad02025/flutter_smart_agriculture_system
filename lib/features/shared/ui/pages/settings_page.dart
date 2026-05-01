import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/core/config/app_runtime_config.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/bloc/auth_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/ui/bloc/auth_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A verification link will be sent to the new email address.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              final pass = passController.text;

              if (email.isEmpty || !email.contains('@')) {
                _showSnackBar('Please enter a valid email address.');
                return;
              }
              if (pass.isEmpty) {
                _showSnackBar('Please enter your current password to verify.');
                return;
              }

              context.read<AuthCubit>().changeEmail(
                currentPassword: pass,
                newEmail: email,
              );
              Navigator.pop(context);
            },
            child: const Text('Verify & Change'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Minimum 6 characters',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final current = currentPassController.text;
              final newPass = newPassController.text;

              if (current.isEmpty) {
                _showSnackBar('Current password is required.');
                return;
              }
              if (newPass.length < 6) {
                _showSnackBar('New password must be at least 6 characters.');
                return;
              }

              context.read<AuthCubit>().changePassword(
                currentPassword: current,
                newPassword: newPass,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          final isSuccess =
              state.message.contains('successfully') ||
              state.message.contains('sent to');
          _showSnackBar(state.message, isError: !isSuccess);
        }
      },
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1F5B24), Color(0xFF4C8A2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Customize how the app behaves and alerts you.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Security',
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Change Email'),
                  onTap: _showChangeEmailDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'Notifications',
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.pushNotifications,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setPushNotifications,
                      title: const Text('Push notifications'),
                      subtitle: const Text(
                        'Show alerts when disease is detected',
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.strongAlertMode,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setStrongAlertMode,
                      title: const Text('Strong alert mode'),
                      subtitle: const Text(
                        'Use stronger colors for disease warnings',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'Analysis',
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.autoAnalyze,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setAutoAnalyze,
                      title: const Text('Auto analyze after upload'),
                      subtitle: const Text('Run disease detection immediately'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showAdvancedDetails,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowAdvancedDetails,
                      title: const Text('Show analysis details'),
                      subtitle: const Text(
                        'Display AI confidence and raw labels',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'System',
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showDeveloperTools,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowDeveloperTools,
                      title: const Text('Developer cloud tools'),
                      subtitle: const Text(
                        'Enable Firebase testing and diagnostics',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'About',
              children: const <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.science_outlined),
                  title: Text('Model source'),
                  subtitle: Text('Cloud AI Cucumber Disease Detection'),
                ),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Storage'),
                  subtitle: Text('Firebase Realtime Database'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

