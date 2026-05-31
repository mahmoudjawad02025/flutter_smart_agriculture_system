import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../features/firebase_data/models/farm_payload.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../localization/app_strings.dart';

/// Observes the pumps root and writes minimal ON/OFF logs when pump values
/// change. Classifies logs as auto vs manual based on the current `auto`
/// flag at detection time. This centralizes logging so edits to the pumps
/// root (from UI, external console, or automation) are recorded consistently.
class PumpChangeLogger {
  PumpChangeLogger._({required FirebaseDatabase database})
    : _database = database;

  final FirebaseDatabase _database;
  StreamSubscription<DatabaseEvent>? _pumpsSub;
  Map<String, dynamic> _lastPumps = const <String, dynamic>{};

  static PumpChangeLogger? _instance;

  static PumpChangeLogger ensureStarted({required FirebaseDatabase database}) {
    _instance ??= PumpChangeLogger._(database: database)..start();
    return _instance!;
  }

  void start() {
    if (_pumpsSub != null) return;

    _pumpsSub = _database
        .ref(FarmPayload.pumpsPath)
        .onValue
        .listen(
          (DatabaseEvent event) async {
            final Map<String, dynamic> current = _toMap(event.snapshot.value);

            // First snapshot: initialize state and don't log historical values.
            if (_lastPumps.isEmpty) {
              _lastPumps = Map<String, dynamic>.from(current);
              return;
            }

            final bool isAutoMode = (current['auto'] as bool?) ?? false;

            // Examine union of keys to detect additions/removals too.
            final Set<String> keys = {..._lastPumps.keys, ...current.keys};
            for (final String key in keys) {
              if (key == 'auto') continue; // only log pump devices

              final bool prev = _toBool(_lastPumps[key]);
              final bool now = _toBool(current[key]);
              if (prev != now) {
                try {
                  await _writePumpLog(key, now, isAutoMode);
                } catch (_) {
                  // Swallow - logging should not crash the app.
                }
              }
            }

            _lastPumps = Map<String, dynamic>.from(current);
          },
          onError: (Object e, StackTrace s) {
            // Intentionally minimal error handling to avoid noise on startup.
          },
        );
  }

  Future<void> _writePumpLog(String pumpKey, bool isOn, bool isAuto) async {
    final DateTime now = DateTime.now();
    final String iso = now.toUtc().toIso8601String();
    // Capture current sensors and leaf status to make logs informative.
    Map<String, dynamic> sensorsSnapshot = <String, dynamic>{};
    Map<String, dynamic> leafSnapshot = <String, dynamic>{};
    try {
      final DataSnapshot s = await _database.ref(FarmPayload.sensorsPath).get();
      sensorsSnapshot = _toMap(s.value);
    } catch (_) {
      sensorsSnapshot = <String, dynamic>{};
    }
    try {
      final DataSnapshot l = await _database.ref(FarmPayload.leafPath).get();
      leafSnapshot = _toMap(l.value);
    } catch (_) {
      leafSnapshot = <String, dynamic>{};
    }

    final Map<String, dynamic> sensorsToWrite = <String, dynamic>{};
    void tryCopy(String key) {
      if (sensorsSnapshot.containsKey(key) && sensorsSnapshot[key] != null) {
        sensorsToWrite[key] = sensorsSnapshot[key];
      }
    }

    tryCopy('moist');
    tryCopy('temp');
    tryCopy('hum');
    tryCopy('n');
    tryCopy('p');
    tryCopy('k');

    final String? leafStatus =
        (leafSnapshot['status'] ??
                leafSnapshot['leaf'] ??
                leafSnapshot['state'])
            ?.toString();

    final Map<String, dynamic> payload = <String, dynamic>{
      'time': iso,
      'pump': pumpKey,
      'action': isOn ? 'ON' : 'OFF',
    };
    if (sensorsToWrite.isNotEmpty) payload['sensors'] = sensorsToWrite;
    if (leafStatus != null && leafStatus.isNotEmpty)
      payload['leaf_status'] = leafStatus;

    if (isAuto) {
      final String id = '${pumpKey}_${now.microsecondsSinceEpoch}';
      await _database
          .ref('${FarmPayload.autoLogsPath}/$pumpKey/$id')
          .set(payload);
    } else {
      final String id = 'manual_${now.millisecondsSinceEpoch}';
      await _database.ref('${FarmPayload.manualLogsPath}/$id').set(payload);
    }

    // Also create a simple notification for this log so users get alerted.
    try {
      final String pumpDisplay = AppStrings.displayPumpName(pumpKey);
      final String actionText = isOn ? AppStrings.on : AppStrings.off;
      final String title = '$pumpDisplay : $actionText';
      final String message = isAuto
          ? 'تم بواسطة النظام التلقائي'
          : 'تم بواسطة المستخدم يدوياً';

      final NotificationsService svc = NotificationsService(
        database: _database,
      );
      await svc.addLogNotification(
        title: title,
        message: message,
        code: 'pump_log',
        createdAt: now,
      );
    } catch (_) {
      // best-effort; do not fail logging on notification errors
    }
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final String low = value.toLowerCase();
      return low == 'true' || low == '1';
    }
    return false;
  }

  Future<void> dispose() async {
    await _pumpsSub?.cancel();
    _pumpsSub = null;
  }
}
