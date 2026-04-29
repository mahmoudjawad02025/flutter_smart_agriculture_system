import 'package:flutter/material.dart';
import 'package:smart_cucumber_agriculture_system/core/di/app_di.dart';
import 'package:smart_cucumber_agriculture_system/logic/usecases/watch_logs.dart';

class LogsHistoryPage extends StatelessWidget {
  const LogsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WatchLogs watchLogs = AppDi.provideWatchLogsUsecase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: watchLogs.call(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, dynamic>? raw = snapshot.data;
          if (raw == null) {
            return const Center(child: Text('No logs found.'));
          }

          final logs = _parseAllLogs(raw);

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    log.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  log.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.isManual)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _LogMetric(Icons.water_drop, '${log.moist}%'),
                            _LogMetric(Icons.thermostat, '${log.temp}°C'),
                            _LogMetric(Icons.air, '${log.hum}%'),
                            _LogMetric(Icons.grass, '${log.n}'),
                            _LogMetric(Icons.spa, '${log.p}'),
                            _LogMetric(Icons.eco, '${log.k}'),
                          ],
                        ),
                      )
                    else
                      Text(log.subtitle ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${log.leafStatus ?? 'Unknown'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Text(
                  '${log.time.day}/${log.time.month}\n${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_DetailedLogItem> _parseAllLogs(Map<String, dynamic> logsData) {
    final List<_DetailedLogItem> allLogs = [];

    _toMap(logsData['fert_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _DetailedLogItem(
          time: _parseDate(data['time']),
          title: 'Fertilizer: ${data['type'] ?? 'Apply'}',
          subtitle: 'Value: ${data['val'] ?? '-'}',
          icon: Icons.science_outlined,
        ),
      );
    });

    _toMap(logsData['water_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _DetailedLogItem(
          time: _parseDate(data['time']),
          title: 'Watering Session',
          subtitle: 'Irrigation pump activated',
          icon: Icons.water_drop_outlined,
        ),
      );
    });

    _toMap(logsData['upload_log']).forEach((key, val) {
      final data = _toMap(val);
      allLogs.add(
        _DetailedLogItem(
          time: _parseDate(data['time']),
          title: 'AI Scan Result',
          subtitle: 'Detection: ${data['res'] ?? 'Healthy'}',
          icon: Icons.auto_awesome_outlined,
          leafStatus: data['res']?.toString(),
        ),
      );
    });

    _toMap(logsData['manual_log']).forEach((key, val) {
      final data = _toMap(val);
      final state = _toMap(data['state']);
      allLogs.add(
        _DetailedLogItem(
          time: _parseDate(data['time']),
          title: 'Manual ${data['pump']}: ${data['action']}',
          icon: Icons.touch_app_outlined,
          isManual: true,
          leafStatus: state['status']?.toString(),
          n: state['n']?.toString() ?? '?',
          p: state['p']?.toString() ?? '?',
          k: state['k']?.toString() ?? '?',
          hum: state['hum']?.toString() ?? '?',
          moist: state['moist']?.toString() ?? '?',
          temp: state['temp']?.toString() ?? '?',
        ),
      );
    });

    allLogs.sort((a, b) => b.time.compareTo(a.time));
    return allLogs;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
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

class _LogMetric extends StatelessWidget {
  const _LogMetric(this.icon, this.value);
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailedLogItem {
  final DateTime time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? leafStatus;
  final bool isManual;
  final String? n, p, k, moist, temp, hum;

  _DetailedLogItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    this.leafStatus,
    this.isManual = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
    this.hum,
  });
}
