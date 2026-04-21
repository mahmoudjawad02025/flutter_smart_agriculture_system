import 'package:flutter/material.dart';

import '../../../core/config/app_access_control.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _autoAnalyze = true;
  bool _debugLogging = true;
  bool _darkAlertMode = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            title: 'Access',
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: AppAccessControl.instance.skipLogin,
                builder: (BuildContext context, bool skipLogin, Widget? child) {
                  return SwitchListTile(
                    value: skipLogin,
                    onChanged: (bool value) {
                      AppAccessControl.instance.setSkipLogin(value);
                    },
                    title: const Text('Skip login screen'),
                    subtitle: const Text(
                      'Open the app shell directly for quick testing.',
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Notifications',
            children: <Widget>[
              SwitchListTile(
                value: _pushNotifications,
                onChanged: (bool value) =>
                    setState(() => _pushNotifications = value),
                title: const Text('Push notifications'),
                subtitle: const Text('Show alerts when disease is detected'),
              ),
              SwitchListTile(
                value: _darkAlertMode,
                onChanged: (bool value) =>
                    setState(() => _darkAlertMode = value),
                title: const Text('Strong alert mode'),
                subtitle: const Text(
                  'Use stronger colors for disease warnings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: 'Analysis',
            children: <Widget>[
              SwitchListTile(
                value: _autoAnalyze,
                onChanged: (bool value) => setState(() => _autoAnalyze = value),
                title: const Text('Auto analyze after upload'),
                subtitle: const Text('Run disease detection immediately'),
              ),
              SwitchListTile(
                value: _debugLogging,
                onChanged: (bool value) =>
                    setState(() => _debugLogging = value),
                title: const Text('Debug logging'),
                subtitle: const Text('Show diagnostic logs in console'),
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
                subtitle: Text('Roboflow cucumber disease detection'),
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
