import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/core/config/app_runtime_config.dart';
import 'package:smart_cucumber_agriculture_system/ui/bloc/auth_bloc.dart';
import 'package:smart_cucumber_agriculture_system/ui/bloc/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/admin_users_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/configurations_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/dashboard_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/disease_detection_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/firebase_data_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/notifications_page.dart';
import 'package:smart_cucumber_agriculture_system/ui/pages/settings_page.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  static const List<String> _titles = <String>[
    'Farm Dashboard',
    'AI Disease Detection',
    'Farm Configurations',
    'Settings',
  ];

  late final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const DiseaseDetectionPage(),
    const ConfigurationsPage(),
    const SettingsPage(),
  ];

  void _goToPage(int index) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }

  void _openFirebaseTest() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FirebaseDataPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                _appIconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_titles[_currentIndex])),
          ],
        ),
        actions: <Widget>[const NotificationBadge()],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: const AssetImage(_appIconAsset),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cucumber Pro Menu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              _DrawerNavTile(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                onTap: () => _goToPage(0),
              ),
              _DrawerNavTile(
                icon: Icons.auto_awesome_outlined,
                label: 'AI Detection',
                onTap: () => _goToPage(1),
              ),
              _DrawerNavTile(
                icon: Icons.tune_outlined,
                label: 'Configurations',
                onTap: () => _goToPage(2),
              ),
              _DrawerNavTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _goToPage(3),
              ),
              _DrawerNavTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  Navigator.of(context).pop();
                  _openNotifications();
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppRuntimeConfig.showDeveloperTools,
                builder: (context, showDev, _) {
                  if (!showDev) return const SizedBox.shrink();
                  return _DrawerNavTile(
                    icon: Icons.cloud_outlined,
                    label: 'Firebase Diagnostics',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openFirebaseTest();
                    },
                  );
                },
              ),
              const Divider(indent: 20, endIndent: 20),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated &&
                      state.user.role == 'admin') {
                    return _DrawerNavTile(
                      icon: Icons.people_outline,
                      label: 'User Management',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUsersPage(),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _DrawerNavTile(
                icon: Icons.logout,
                label: 'Log Out',
                onTap: () => context.read<AuthCubit>().logout(),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToPage,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Config',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        minLeadingWidth: 30,
        leading: Icon(icon),
        title: Text(label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
