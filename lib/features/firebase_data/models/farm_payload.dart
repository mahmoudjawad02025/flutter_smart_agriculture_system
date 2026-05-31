import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class FarmPayload {
  const FarmPayload._();

  // When empty, operate at DB root (top-level keys). If non-empty,
  // keep all keys under that wrapper.
  static const String rootPath = '';
  static const String usersPath = 'users';

  static String get sensorsPath =>
      rootPath.isEmpty ? 'sensors' : '$rootPath/sensors';
  static String get dailyAveragesPath => '$extraPath/avarages';
  static String get leafPath => rootPath.isEmpty ? 'leaf' : '$rootPath/leaf';
  static String get configPath =>
      rootPath.isEmpty ? 'config' : '$rootPath/config';
  static String get pumpsPath => '$configPath/pumps';

  static String get extraPath => rootPath.isEmpty ? 'extra' : '$rootPath/extra';
  static String get notificationsPath => '$extraPath/notifications';
  static String get notificationItemsPath => '$notificationsPath/items';
  static String get unreadCountPath => '$notificationsPath/unread_count';
  static String get logsPath => '$extraPath/logs';
  static String get manualLogsPath => '$logsPath/manual_logs';
  static String get autoLogsPath => '$logsPath/auto_logs';

  static String get nitrogenPath => '$sensorsPath/n';

  static Map<String, dynamic> _fallbackSampleData() {
    // Minimal skeleton fallback only — primary source is the JSON asset.
    return <String, dynamic>{
      'sensors': <String, dynamic>{},
      'leaf': <String, dynamic>{},
      'config': <String, dynamic>{},
      'users': <String, dynamic>{},
      'extra': <String, dynamic>{
        'notifications': <String, dynamic>{},
        'logs': <String, dynamic>{},
      },
    };
  }

  static Future<Map<String, dynamic>> loadSampleData() async {
    try {
      final String jsonText = await rootBundle.loadString(
        'lib/docs/firebase_struct.json',
      );
      final dynamic decoded = json.decode(jsonText);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fall back to built-in sample data
    }
    return _fallbackSampleData();
  }

  // Public API: return canonical sample data (from JSON asset when available).
  static Future<Map<String, dynamic>> sampleData() async {
    return await loadSampleData();
  }

  static DatabaseReference rootRef(FirebaseDatabase db) {
    return rootPath.isEmpty ? db.ref() : db.ref(rootPath);
  }

  static Future<void> ensureDefaults(FirebaseDatabase database) async {
    final DatabaseReference farmRef = rootRef(database);
    final DataSnapshot farmSnapshot = await farmRef.get();
    final Map<String, dynamic> defaults = await loadSampleData();
    if (!farmSnapshot.exists || farmSnapshot.value == null) {
      await farmRef.set(defaults);
    } else {
      final Map<String, dynamic> current = _toMap(farmSnapshot.value);
      final Map<String, dynamic> missing = <String, dynamic>{};
      _collectMissing('', defaults, current, missing);
      if (missing.isNotEmpty) {
        await farmRef.update(missing);
      }
    }

    final DatabaseReference usersRef = database.ref(usersPath);
    final DataSnapshot usersSnapshot = await usersRef.get();
    if (!usersSnapshot.exists || usersSnapshot.value == null) {
      await usersRef.set(<String, dynamic>{});
    }
  }

  static void _collectMissing(
    String path,
    Map<String, dynamic> defaults,
    Map<String, dynamic> current,
    Map<String, dynamic> missing,
  ) {
    for (final MapEntry<String, dynamic> entry in defaults.entries) {
      final String nextPath = path.isEmpty ? entry.key : '$path/${entry.key}';
      final dynamic currentValue = current[entry.key];
      final dynamic defaultValue = entry.value;

      if (currentValue == null) {
        missing[nextPath] = defaultValue;
        continue;
      }

      if (defaultValue is Map && currentValue is Map) {
        _collectMissing(
          nextPath,
          Map<String, dynamic>.from(defaultValue),
          Map<String, dynamic>.from(currentValue),
          missing,
        );
      }
    }
  }

  static Map<String, dynamic> _toMap(dynamic value) {
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
}
