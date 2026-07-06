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
  final Set<int> _mountedTabIndices = <int>{0};

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
      _mountedTabIndices.add(index);
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
        backgroundColor: const Color(0xFFF7FBF4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const _DrawerHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  children: <Widget>[
                    const _DrawerSectionLabel(title: 'التنقل'),
                    _DrawerNavTile(
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard_rounded,
                      label: 'لوحة التحكم',
                      isSelected: _currentIndex == 0,
                      color: const Color(0xFF2E7D32),
                      onTap: () => _goToPage(0),
                    ),
                    _DrawerNavTile(
                      icon: Icons.auto_awesome_outlined,
                      selectedIcon: Icons.auto_awesome_rounded,
                      label: 'كشف الأمراض',
                      isSelected: _currentIndex == 1,
                      color: const Color(0xFF6A1B9A),
                      onTap: () => _goToPage(1),
                    ),
                    _DrawerNavTile(
                      icon: Icons.tune_outlined,
                      selectedIcon: Icons.tune_rounded,
                      label: 'تكوين المزرعة',
                      isSelected: _currentIndex == 2,
                      color: const Color(0xFF1565C0),
                      onTap: () => _goToPage(2),
                    ),
                    _DrawerNavTile(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                      label: 'الإعدادات',
                      isSelected: _currentIndex == 3,
                      color: const Color(0xFF546E7A),
                      onTap: () => _goToPage(3),
                    ),
                    const SizedBox(height: 8),
                    const _DrawerSectionLabel(title: 'النشاط'),
                    BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, state) {
                        final int unread = state.unreadCount;
                        return _DrawerNavTile(
                          icon: Icons.notifications_outlined,
                          selectedIcon: Icons.notifications_rounded,
                          label: 'الإشعارات',
                          color: const Color(0xFFE65100),
                          badgeCount: unread,
                          onTap: () {
                            Navigator.of(context).pop();
                            _openNotifications();
                          },
                        );
                      },
                    ),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated &&
                            state.user.role == 'admin') {
                          return _DrawerNavTile(
                            icon: Icons.people_outline_rounded,
                            selectedIcon: Icons.people_rounded,
                            label: 'إدارة المستخدمين',
                            color: const Color(0xFF00838F),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => const AdminUsersPage(),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _DrawerNavTile(
                  icon: Icons.logout_rounded,
                  selectedIcon: Icons.logout_rounded,
                  label: 'تسجيل الخروج',
                  color: const Color(0xFFC62828),
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<AuthCubit>().logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(_pages.length, (int index) {
          if (!_mountedTabIndices.contains(index)) {
            return const SizedBox.shrink();
          }
          return _pages[index];
        }),
      ),
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF7CB342)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final String subtitle;
          if (state is AuthAuthenticated) {
            final String name = state.user.displayName?.trim() ?? '';
            subtitle = name.isNotEmpty ? name : state.user.email;
          } else {
            subtitle = 'مرحبًا بك في المزرعة الذكية';
          }

          return Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    AppStrings.appIconAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isSelected = false,
    this.isDestructive = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isSelected;
  final bool isDestructive;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final Color background = isSelected
        ? color.withValues(alpha: 0.14)
        : Colors.white;
    final Color borderColor = isSelected
        ? color.withValues(alpha: 0.35)
        : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDestructive ? 0.12 : 0.15),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                        color: isDestructive
                            ? color
                            : const Color(0xFF263238),
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
