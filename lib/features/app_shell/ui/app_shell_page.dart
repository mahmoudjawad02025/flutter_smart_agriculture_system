import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_strings.dart';
import '../../configurations/ui/configurations_page.dart';
import '../../dashboard/ui/dashboard_page.dart';
import '../../disease_detection/ui/disease_detection_page.dart';
// Firebase diagnostics page removed
import '../../notifications/ui/notifications_page.dart';
import '../../notifications/cubit/notifications_cubit.dart';
import '../../settings/ui/settings_page.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/ui/admin_users_page.dart';

// use centralized app icon/title from AppStrings

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  static const List<String> _titles = <String>[
    'لوحة تحكم المزرعة',
    'كشف الأمراض بالذكاء الاصطناعي',
    'تكوين المزرعة',
    'الإعدادات',
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

  // Firebase diagnostics removed from release build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppStrings.appIconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_titles[_currentIndex])),
          ],
        ),
        actions: <Widget>[
          Row(children: [const NotificationBadge(), const SizedBox(width: 8)]),
        ],
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        AppStrings.appIconAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.appTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              _DrawerNavTile(
                icon: Icons.dashboard_outlined,
                label: 'لوحة التحكم',
                onTap: () => _goToPage(0),
              ),
              _DrawerNavTile(
                icon: Icons.auto_awesome_outlined,
                label: 'كشف الأمراض',
                onTap: () => _goToPage(1),
              ),
              _DrawerNavTile(
                icon: Icons.tune_outlined,
                label: 'تكوين',
                onTap: () => _goToPage(2),
              ),
              _DrawerNavTile(
                icon: Icons.settings_outlined,
                label: 'الإعدادات',
                onTap: () => _goToPage(3),
              ),
              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  final int unread = state.unreadCount;
                  return _DrawerNavTile(
                    icon: Icons.notifications_outlined,
                    label: 'الإشعارات',
                    trailing: unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      _openNotifications();
                    },
                  );
                },
              ),
              // Developer cloud tools removed
              const Divider(indent: 20, endIndent: 20),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated &&
                      state.user.role == 'admin') {
                    return _DrawerNavTile(
                      icon: Icons.people_outline,
                      label: 'إدارة المستخدمين',
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
                label: 'تسجيل الخروج',
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
            label: 'لوحة التحكم',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'الذكاء الاصطناعي',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'تكوين',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
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
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

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
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
