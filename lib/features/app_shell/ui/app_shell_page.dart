import 'package:flutter/material.dart';

import '../../dashboard/ui/dashboard_page.dart';
import '../../disease_detection/ui/disease_detection_page.dart';
import '../../firebase_data/ui/firebase_data_page.dart';

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
    'Firebase Read/Write',
    'Settings',
  ];

  late final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const DiseaseDetectionPage(),
    const FirebaseDataPage(),
    const _PlaceholderPage(
      title: 'Settings',
      subtitle: 'Use this page later for thresholds and automation options.',
      icon: Icons.settings_outlined,
    ),
  ];

  void _goToPage(int index) {
    Navigator.of(context).maybePop();
    setState(() {
      _currentIndex = index;
    });
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
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('No notifications right now.')),
                );
            },
            icon: const Icon(Icons.notifications_none_outlined),
          ),
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
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: const AssetImage(_appIconAsset),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Cucumber Menu',
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
                icon: Icons.cloud_outlined,
                label: 'Firebase Test',
                onTap: () => _goToPage(2),
              ),
              _DrawerNavTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _goToPage(3),
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
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud_done),
            label: 'Firebase',
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 52),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
