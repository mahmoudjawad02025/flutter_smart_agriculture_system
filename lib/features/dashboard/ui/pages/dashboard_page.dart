import 'package:flutter/material.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/data/models/farm_payload_model.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/usecases/get_farm_data_once.dart';
import 'package:smart_cucumber_agriculture_system/core/di/app_di.dart';

import 'logs_history_page.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final GetFarmDataOnce _getFarmData;

  @override
  void initState() {
    super.initState();
    _getFarmData = AppDi.provideGetFarmDataOnceUsecase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getFarmData.call(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<Map<String, dynamic>?> snapshot,
            ) {
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

              final dynamic raw = snapshot.data;
              if (raw is! Map) {
                return const _MessageView(
                  icon: Icons.cloud_off_outlined,
                  title: 'No Firebase data yet',
                  subtitle: 'Use Firebase tab to write sample data first.',
                );
              }

              final Map<String, dynamic> data = _toMap(raw);
              final Map<String, dynamic> live = _toMap(data['live']);
              final Map<String, dynamic> sensors = _toMap(data['sensors']);
              final Map<String, dynamic> source = live.isNotEmpty
                  ? live
                  : sensors;
              final Map<String, dynamic> leaf = _toMap(data['leaf']);

              final String time = '${source['time'] ?? '-'}';
              final String leafStatus = '${leaf['status'] ?? '-'}';
              final bool needsFix = leaf['needs_fix'] == true;
              final String reuploadAt = '${leaf['reupload_at'] ?? ''}';

              final Map<String, dynamic> pumps = _toMap(
                data['actions']?['pumps'],
              );
              final Map<String, dynamic> logsData = _toMap(data['logs']);

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
                  _PumpsSnapshot(pumps: pumps),
                  const SizedBox(height: 14),
                  _LogsSnapshotFromMap(logsData: logsData),
                ],
              );
            },
      ),
    );
  }
}

class _LogsSnapshotFromMap extends StatelessWidget {
  const _LogsSnapshotFromMap({required this.logsData});
  final Map<String, dynamic> logsData;

  @override
  Widget build(BuildContext context) {
    if (logsData.isEmpty) return const SizedBox.shrink();

    final List<_LogItem> allLogs = [];

    // Parse Fertilizer Logs
    _toMap(logsData['fert_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _LogItem(
          time: _parseDate(data['time']),
          title: 'Fertilizer: ${data['type'] ?? 'Apply'}',
          subtitle: 'Value: ${data['val'] ?? '-'}',
          icon: Icons.science_outlined,
        ),
      );
    });

    // Parse Water Logs
    _toMap(logsData['water_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _LogItem(
          time: _parseDate(data['time']),
          title: 'Watering Session',
          subtitle: 'Irrigation pump activated',
          icon: Icons.water_drop_outlined,
        ),
      );
    });

    // Parse AI Upload Logs
    _toMap(logsData['upload_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _LogItem(
          time: _parseDate(data['time']),
          title: 'AI Scan Result',
          subtitle: 'Detection: ${data['res'] ?? 'Healthy'}',
          icon: Icons.auto_awesome_outlined,
        ),
      );
    });

    // Parse Manual Logs
    _toMap(logsData['manual_log']).forEach((key, val) {
      final data = _toMap(val);
      final state = _toMap(data['state']);
      allLogs.add(
        _LogItem(
          time: _parseDate(data['time']),
          title: 'Manual ${data['pump']}: ${data['action']}',
          icon: Icons.touch_app_outlined,
          isManual: true,
          n: state['n']?.toString() ?? '?',
          p: state['p']?.toString() ?? '?',
          k: state['k']?.toString() ?? '?',
          moist: state['moist']?.toString() ?? '?',
          temp: state['temp']?.toString() ?? '?',
        ),
      );
    });

    allLogs.sort((a, b) => b.time.compareTo(a.time));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.history_outlined,
                    size: 20,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const LogsHistoryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (allLogs.isEmpty)
              const Text('No logs found.', style: TextStyle(color: Colors.grey))
            else
              Column(
                children: allLogs.take(5).map((log) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      radius: 18,
                      child: Icon(
                        log.icon,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      log.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: log.isManual
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _MiniMetric(Icons.water_drop, log.moist!),
                                  _MiniMetric(Icons.thermostat, log.temp!),
                                  _MiniMetric(Icons.grass, log.n!),
                                  _MiniMetric(Icons.spa, log.p!),
                                  _MiniMetric(Icons.eco, log.k!),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            log.subtitle ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                    trailing: Text(
                      '${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.icon, this.value);
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem {
  final DateTime time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isManual;
  final String? n, p, k, moist, temp;

  _LogItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isManual = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
  });
}

class _PumpsSnapshot extends StatelessWidget {
  const _PumpsSnapshot({required this.pumps});
  final Map<String, dynamic> pumps;

  @override
  Widget build(BuildContext context) {
    if (pumps.isEmpty) return const SizedBox.shrink();
    return _PumpsCard(
      water: pumps['water'] == true,
      fert: pumps['fert'] == true,
      auto: pumps['auto'] == true,
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
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
  final bool water, fert, auto;

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
  final String title, subtitle;
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

