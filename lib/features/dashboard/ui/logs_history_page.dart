import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_streams.dart';
import '../../../core/localization/app_strings.dart';
import '../../../features/firebase_data/models/farm_payload.dart';

class LogsHistoryPage extends StatelessWidget {
  const LogsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل نظام الأحداث'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {}, // StreamBuilder handles this
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'حذف الكل',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف كل السجلات'),
                  content: const Text(
                    'هل تريد حذف جميع السجلات نهائياً؟ لا يمكن التراجع.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              // Use a SnackBar as an indeterminate progress indicator to avoid
              // using BuildContext across async gaps.
              final SnackBar loading = SnackBar(
                content: const Text('جارٍ حذف السجلات...'),
                duration: const Duration(days: 1),
              );
              scaffoldMessenger.showSnackBar(loading);

              try {
                await FirebaseDatabase.instance
                    .ref(FarmPayload.logsPath)
                    .remove();
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('تم حذف السجلات.')),
                );
              } catch (e) {
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('فشل حذف السجلات: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        initialData: FirebaseStreams.lastLogsEvent,
        stream: FirebaseStreams.logsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('فشل تحميل السجلات: ${snapshot.error}'));
          }

          // Prefer showing available data (including `initialData`) over
          // an unconditional waiting spinner. Only show the spinner while
          // the stream is still waiting and no data is available yet.
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('لا توجد سجلات.'));
          }

          final Map<String, dynamic> logsNode = _toMap(
            snapshot.data!.snapshot.value,
          );
          final logs = _parseAllLogs(logsNode);

          if (logs.isEmpty) {
            return const Center(child: Text('لا توجد سجلات.'));
          }

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
                    if (log.subtitle != null && log.subtitle!.isNotEmpty)
                      Text(log.subtitle!),
                    if (log.hasSensors)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _LogMetric(Icons.water_drop, '${log.moist}%'),
                            _LogMetric(Icons.thermostat, '${log.temp}°م'),
                            _LogMetric(Icons.air, '${log.hum}%'),
                            _LogMetric(Icons.eco, '${log.n}'),
                            _LogMetric(Icons.eco, '${log.p}'),
                            _LogMetric(Icons.eco, '${log.k}'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'الحالة: ${log.leafStatus != null ? AppStrings.displayLeafStatus(log.leafStatus!) : 'غير معروف'}',
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

  List<_DetailedLogItem> _parseAllLogs(dynamic raw) {
    final Map<String, dynamic> logsData = _toMap(raw);
    final List<_DetailedLogItem> allLogs = [];

    void addIfPumpLog(
      Map<String, dynamic> data, {
      bool isAuto = false,
      bool isManual = false,
    }) {
      if (data.isEmpty) return;
      if (data['debug'] == true) return; // ignore debug entries

      final String action = data['action']?.toString().toUpperCase() ?? '';
      final String pump = data['pump']?.toString() ?? '';
      if (action != 'ON' && action != 'OFF') return;

      final String lowPump = pump.toLowerCase();
      IconData icon = Icons.auto_awesome_outlined;
      String title;

      if (lowPump.contains('water') || pump.toUpperCase() == 'WATER') {
        icon = Icons.water_drop_outlined;
        title =
            '${isAuto ? 'ري تلقائي' : 'ري يدوي'} : ${AppStrings.displayAction(action)}';
      } else if (lowPump.contains('fert') ||
          pump.toUpperCase() == 'FERTILIZER') {
        icon = Icons.science_outlined;
        title =
            '${AppStrings.displayPumpName(pump)} ${isAuto ? 'تلقائي' : 'يدوي'} : ${AppStrings.displayAction(action)}';
      } else {
        icon = Icons.touch_app_outlined;
        title =
            '${AppStrings.displayPumpName(pump)} ${isAuto ? 'تلقائي' : 'يدوي'} : ${AppStrings.displayAction(action)}';
      }

      allLogs.add(
        _DetailedLogItem(
          time: _parseDate(data['time']),
          title: title,
          subtitle: null,
          icon: icon,
        ),
      );
    }

    // Auto logs
    final Map<String, dynamic> autoLogs = _toMap(logsData['auto_logs']);
    autoLogs.forEach((kind, entries) {
      final Map<String, dynamic> kindLogs = _toMap(entries);
      kindLogs.forEach((key, val) {
        final data = _toMap(val);
        addIfPumpLog(data, isAuto: true);
      });
    });

    // Manual logs
    final Map<String, dynamic> manualLogs = _toMap(logsData['manual_logs']);
    manualLogs.forEach((key, val) {
      final data = _toMap(val);
      addIfPumpLog(data, isManual: true);
    });

    // Also scan top-level entries (in case snapshot pointed directly at a logs node)
    logsData.forEach((key, val) {
      final Map<String, dynamic> candidate = _toMap(val);
      if (candidate.containsKey('action') && candidate.containsKey('pump')) {
        addIfPumpLog(candidate);
      }
    });

    allLogs.sort((a, b) => b.time.compareTo(a.time));
    return allLogs;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) {
      final Map<String, dynamic> map = {};
      for (int i = 0; i < value.length; i++) {
        if (value[i] != null) {
          map[i.toString()] = value[i];
        }
      }
      return map;
    }
    return <String, dynamic>{};
  }

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      try {
        return DateTime.parse(val).toLocal();
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
          style: TextStyle(
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
  final bool hasSensors;
  final String? n, p, k, moist, temp, hum;

  _DetailedLogItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    this.leafStatus,
    this.hasSensors = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
    this.hum,
  });
}
