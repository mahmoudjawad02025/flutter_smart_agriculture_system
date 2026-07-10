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
  static String get leafPath => rootPath.isEmpty ? 'leaf' : '$rootPath/leaf';
  static String get configPath =>
      rootPath.isEmpty ? 'config' : '$rootPath/config';
  static String get pumpsPath => '$configPath/pumps';
  static String get tanksPath => '$configPath/tanks';
  static String get autoFertPath => '$configPath/auto_fert';
  static String get wifiPath => '$configPath/wifi';
  static String get refreshTimePath => '$configPath/refresh_time';

  /// ESP32 main-loop delay bounds (milliseconds).
  static const int minRefreshTimeMs = 1;
  static const int maxRefreshTimeMs = 3600000;
  static const int defaultRefreshTimeMs = 5000;

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
      'config': <String, dynamic>{
        'wifi': <String, dynamic>{
          'old_ssid': '',
          'old_pass': '',
          'new_ssid': '',
          'new_pass': '',
        },
        'refresh_time': defaultRefreshTimeMs,
      },
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
        'lib/core/assets/data/firebase_struct.json',
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

    await _migrateLegacyAutoFertilizerPath(farmRef);
    await _migrateLegacyWifiFields(farmRef);

    final DatabaseReference usersRef = database.ref(usersPath);
    final DataSnapshot usersSnapshot = await usersRef.get();
    if (!usersSnapshot.exists || usersSnapshot.value == null) {
      await usersRef.set(<String, dynamic>{});
    }
  }

  static Future<void> _migrateLegacyAutoFertilizerPath(
    DatabaseReference farmRef,
  ) async {
    final DataSnapshot legacySnapshot = await farmRef
        .child('config/auto_fertilizer')
        .get();
    if (!legacySnapshot.exists || legacySnapshot.value == null) {
      return;
    }

    final Map<String, dynamic> legacy = _toMap(legacySnapshot.value);
    final DataSnapshot currentSnapshot = await farmRef
        .child('config/auto_fert')
        .get();

    if (!currentSnapshot.exists || currentSnapshot.value == null) {
      await farmRef.child('config/auto_fert').set(legacy);
    } else {
      final Map<String, dynamic> current = _toMap(currentSnapshot.value);
      await farmRef.child('config/auto_fert').update(<String, dynamic>{
        ...current,
        ...legacy,
      });
    }

    await farmRef.child('config/auto_fertilizer').remove();
  }

  static Future<void> _migrateLegacyWifiFields(
    DatabaseReference farmRef,
  ) async {
    final DataSnapshot wifiSnapshot = await farmRef.child('config/wifi').get();
    if (!wifiSnapshot.exists || wifiSnapshot.value == null) {
      return;
    }

    final Map<String, dynamic> wifi = _toMap(wifiSnapshot.value);
    final Map<String, dynamic> updates = <String, dynamic>{};

    String pickValue(List<String> keys) {
      for (final String key in keys) {
        final String value = '${wifi[key] ?? ''}'.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
      return '';
    }

    final String oldSsid = pickValue(<String>['old_ssid', 'old_name', 'name']);
    final String oldPass = pickValue(<String>[
      'old_pass',
      'old_password',
      'password',
    ]);
    final String newSsid = pickValue(<String>['new_ssid', 'new_name']);
    final String newPass = pickValue(<String>['new_pass']);

    if ('${wifi['old_ssid'] ?? ''}'.trim().isEmpty && oldSsid.isNotEmpty) {
      updates['old_ssid'] = oldSsid;
    }
    if ('${wifi['old_pass'] ?? ''}'.isEmpty && oldPass.isNotEmpty) {
      updates['old_pass'] = oldPass;
    }
    if ('${wifi['new_ssid'] ?? ''}'.trim().isEmpty && newSsid.isNotEmpty) {
      updates['new_ssid'] = newSsid;
    }
    if ('${wifi['new_pass'] ?? ''}'.isEmpty && newPass.isNotEmpty) {
      updates['new_pass'] = newPass;
    }

    if (updates.isNotEmpty) {
      await farmRef.child('config/wifi').update(updates);
    }

    for (final String legacyKey in <String>[
      'name',
      'password',
      'old_name',
      'old_password',
      'new_name',
    ]) {
      if (wifi.containsKey(legacyKey)) {
        await farmRef.child('config/wifi/$legacyKey').remove();
      }
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
