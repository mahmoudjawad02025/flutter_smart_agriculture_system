import 'package:flutter/material.dart';

import '../../features/firebase_data/models/farm_payload.dart';
import '../localization/app_strings.dart';

/// Parsed pump activity log written by ESP32 under `extra/logs`.
class PumpLogEntry {
  const PumpLogEntry({
    required this.time,
    required this.title,
    required this.icon,
    this.leafStatus,
    this.dbPath,
    this.hasSensors = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
    this.hum,
    this.tankCapacity,
  });

  final DateTime time;
  final String title;
  final IconData icon;
  final String? leafStatus;
  final String? dbPath;
  final bool hasSensors;
  final String? n;
  final String? p;
  final String? k;
  final String? moist;
  final String? temp;
  final String? hum;
  final String? tankCapacity;
}

/// Reads ESP32 pump logs from Firebase RTDB (display only — app does not write).
///
/// Structure:
/// ```
/// extra/logs
///   └── <pump>          e.g. water, fert1, fert2
///         └── <log_key>   e.g. fert2_2026-06-29T20:51:26
///               action, mode, pump, leaf_status, tank_capacity, sensors, time
/// ```
///
/// Legacy (still supported): `manual_logs` / `auto_logs` wrappers above `<pump>`.
class PumpLogParser {
  const PumpLogParser._();

  static List<PumpLogEntry> parseLogsNode(dynamic raw) {
    final Map<String, dynamic> logsData = _toMap(raw);
    final List<PumpLogEntry> allLogs = <PumpLogEntry>[];

    final bool hasLegacyBuckets =
        logsData.containsKey('manual_logs') || logsData.containsKey('auto_logs');

    if (hasLegacyBuckets) {
      _collectBucketLogs(
        bucketRoot: _toMap(logsData['auto_logs']),
        basePath: FarmPayload.autoLogsPath,
        defaultAuto: true,
        sink: allLogs,
      );
      _collectBucketLogs(
        bucketRoot: _toMap(logsData['manual_logs']),
        basePath: FarmPayload.manualLogsPath,
        defaultAuto: false,
        sink: allLogs,
      );
    } else {
      _collectBucketLogs(
        bucketRoot: logsData,
        basePath: FarmPayload.logsPath,
        defaultAuto: false,
        sink: allLogs,
      );
    }

    allLogs.sort((PumpLogEntry a, PumpLogEntry b) => b.time.compareTo(a.time));
    return allLogs;
  }

  static void _collectBucketLogs({
    required Map<String, dynamic> bucketRoot,
    required String basePath,
    required bool defaultAuto,
    required List<PumpLogEntry> sink,
  }) {
    for (final MapEntry<String, dynamic> pumpEntry in bucketRoot.entries) {
      final String pumpKind = pumpEntry.key;
      final Map<String, dynamic> pumpNode = _toMap(pumpEntry.value);
      if (pumpNode.isEmpty) continue;

      if (_isLogEntry(pumpNode)) {
        final PumpLogEntry? entry = _parseLogEntry(
          pumpNode,
          defaultAuto: defaultAuto,
          dbPath: '$basePath/$pumpKind',
        );
        if (entry != null) sink.add(entry);
        continue;
      }

      for (final MapEntry<String, dynamic> logEntry in pumpNode.entries) {
        final Map<String, dynamic> data = _toMap(logEntry.value);
        final PumpLogEntry? entry = _parseLogEntry(
          data,
          defaultAuto: defaultAuto,
          dbPath: '$basePath/$pumpKind/${logEntry.key}',
        );
        if (entry != null) sink.add(entry);
      }
    }
  }

  static bool _isLogEntry(Map<String, dynamic> data) {
    if (data.isEmpty || data['debug'] == true) return false;
    final String action = data['action']?.toString().toUpperCase() ?? '';
    return action == 'ON' || action == 'OFF';
  }

  static PumpLogEntry? _parseLogEntry(
    Map<String, dynamic> data, {
    required bool defaultAuto,
    required String dbPath,
  }) {
    if (!_isLogEntry(data)) return null;

    final String action = data['action']!.toString().toUpperCase();
    final String pump = data['pump']?.toString() ?? '';
    final String mode = data['mode']?.toString().toLowerCase() ?? '';
    final bool isAuto = mode == 'auto' || (mode.isEmpty && defaultAuto);

    final Map<String, dynamic> sensorsMap = _toMap(data['sensors']);
    final String? moist = sensorsMap['moist']?.toString();
    final String? temp = sensorsMap['temp']?.toString();
    final String? hum = sensorsMap['hum']?.toString();
    final String? n = sensorsMap['n']?.toString();
    final String? p = sensorsMap['p']?.toString();
    final String? k = sensorsMap['k']?.toString();
    final String? tankCapacity = data['tank_capacity']?.toString();

    String? leafStatus;
    if (data.containsKey('leaf_status')) {
      leafStatus = data['leaf_status']?.toString();
    } else if (data.containsKey('leaf')) {
      final dynamic leafVal = data['leaf'];
      if (leafVal is String) leafStatus = leafVal;
      if (leafVal is Map) leafStatus = _toMap(leafVal)['status']?.toString();
    }

    final String modeLabel = isAuto ? 'تلقائي' : 'يدوي';

    final String lowPump = pump.toLowerCase();
    final IconData icon;
    final String title;

    if (lowPump.contains('water') || pump.toUpperCase() == 'WATER') {
      icon = Icons.water_drop_outlined;
      title = '${isAuto ? 'ري تلقائي' : 'ري يدوي'} : ${AppStrings.displayAction(action)}';
    } else if (lowPump.contains('fert') || pump.toUpperCase() == 'FERTILIZER') {
      icon = Icons.science_outlined;
      title =
          '${AppStrings.displayPumpName(pump)} $modeLabel : ${AppStrings.displayAction(action)}';
    } else {
      icon = Icons.touch_app_outlined;
      title =
          '${AppStrings.displayPumpName(pump)} $modeLabel : ${AppStrings.displayAction(action)}';
    }

    return PumpLogEntry(
      time: _parseDate(data['time']),
      title: title,
      icon: icon,
      leafStatus: leafStatus,
      dbPath: dbPath,
      hasSensors: sensorsMap.isNotEmpty,
      n: n,
      p: p,
      k: k,
      moist: moist,
      temp: temp,
      hum: hum,
      tankCapacity: tankCapacity,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) {
      final Map<String, dynamic> map = <String, dynamic>{};
      for (int i = 0; i < value.length; i++) {
        if (value[i] != null) {
          map[i.toString()] = value[i];
        }
      }
      return map;
    }
    return <String, dynamic>{};
  }
}
