import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../features/firebase_data/models/farm_payload.dart';

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

    if (isAuto) {
      final String id = '${pumpKey}_${now.microsecondsSinceEpoch}';
      await _database.ref('${FarmPayload.autoLogsPath}/$pumpKey/$id').set({
        'time': iso,
        'pump': pumpKey,
        'action': isOn ? 'ON' : 'OFF',
      });
    } else {
      final String id = 'manual_${now.millisecondsSinceEpoch}';
      await _database.ref('${FarmPayload.manualLogsPath}/$id').set({
        'time': iso,
        'pump': pumpKey,
        'action': isOn ? 'ON' : 'OFF',
      });
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
