import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../firebase_data/models/farm_payload.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref(
      FarmPayload.rootPath,
    );

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.error_outline,
              title: 'Failed to load dashboard',
              subtitle: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dynamic raw = snapshot.data!.snapshot.value;
          if (raw is! Map) {
            return const _MessageView(
              icon: Icons.cloud_off_outlined,
              title: 'No Firebase data yet',
              subtitle: 'Use Firebase tab to write sample data first.',
            );
          }

          final Map<String, dynamic> root = Map<String, dynamic>.from(raw);
          final Map<String, dynamic> data = _toMap(root['data']);
          final Map<String, dynamic> live = _toMap(data['live']);
          final Map<String, dynamic> sensors = _toMap(data['sensors']);
          final Map<String, dynamic> source = live.isNotEmpty ? live : sensors;
          final Map<String, dynamic> leaf = _toMap(data['leaf']);
          final Map<String, dynamic> actions = _toMap(root['actions']);
          final Map<String, dynamic> pumps = _toMap(actions['pumps']);

          final String time = '${source['time'] ?? '-'}';
          final String leafStatus = '${leaf['status'] ?? '-'}';
          final bool needsFix = leaf['needs_fix'] == true;
          final String reuploadAt = '${leaf['reupload_at'] ?? ''}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _HeaderCard(
                time: time,
                leafStatus: leafStatus,
                needsFix: needsFix,
                reuploadAt: reuploadAt,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: <Widget>[
                  _MetricCard(
                    title: 'Soil Moisture',
                    value: '${source['moist'] ?? '-'}%',
                    icon: Icons.water_drop_outlined,
                  ),
                  _MetricCard(
                    title: 'Temperature',
                    value: '${source['temp'] ?? '-'} C',
                    icon: Icons.thermostat_outlined,
                  ),
                  _MetricCard(
                    title: 'Humidity',
                    value: '${source['hum'] ?? '-'}%',
                    icon: Icons.air_outlined,
                  ),
                  _MetricCard(
                    title: 'Nitrogen (N)',
                    value: '${source['n'] ?? '-'}',
                    icon: Icons.grass_outlined,
                  ),
                  _MetricCard(
                    title: 'Phosphorus (P)',
                    value: '${source['p'] ?? '-'}',
                    icon: Icons.spa_outlined,
                  ),
                  _MetricCard(
                    title: 'Potassium (K)',
                    value: '${source['k'] ?? '-'}',
                    icon: Icons.eco_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PumpsCard(
                water: pumps['water'] == true,
                fert: pumps['fert'] == true,
                auto: pumps['auto'] == true,
              ),
            ],
          );
        },
      ),
    );
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.time,
    required this.leafStatus,
    required this.needsFix,
    required this.reuploadAt,
  });

  final String time;
  final String leafStatus;
  final bool needsFix;
  final String reuploadAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF558B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  _appIconAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Live Farm Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last update: $time',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.health_and_safety_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leaf status: $leafStatus',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Chip(
                backgroundColor: Colors.white,
                label: Text(needsFix ? 'Needs Fix' : 'Good'),
                avatar: Icon(
                  needsFix ? Icons.warning_amber_outlined : Icons.check_circle,
                  size: 18,
                ),
              ),
            ],
          ),
          if (needsFix && reuploadAt.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Next upload at: $reuploadAt',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _PumpsCard extends StatelessWidget {
  const _PumpsCard({
    required this.water,
    required this.fert,
    required this.auto,
  });

  final bool water;
  final bool fert;
  final bool auto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pump Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _StatusChip(label: 'Water Pump', active: water),
                _StatusChip(label: 'Fertilizer Pump', active: fert),
                _StatusChip(label: 'Auto Mode', active: auto),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.pause_circle_outline,
        size: 18,
      ),
      label: Text('$label: ${active ? 'ON' : 'OFF'}'),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon == Icons.cloud_off_outlined)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _appIconAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
