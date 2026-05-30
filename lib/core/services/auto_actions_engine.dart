import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../config/auto_actions_scenario.dart';
import '../../features/firebase_data/models/farm_payload.dart';

/// In-app automation engine for running auto actions.
///
/// Important: Realtime Database does NOT execute Dart code by itself.
/// This engine must be running inside a live app process (phone/desktop)
/// in order to react to DB changes and update pump states.
class AutoActionsEngine {
  AutoActionsEngine._({required FirebaseDatabase database, required bool debug})
    : _database = database,
      _debug = debug;

  final FirebaseDatabase _database;
  final bool _debug;

  StreamSubscription<DatabaseEvent>? _sensorsSub;
  StreamSubscription<DatabaseEvent>? _leafSub;
  StreamSubscription<DatabaseEvent>? _autoWaterSub;
  StreamSubscription<DatabaseEvent>? _pumpsSub;

  Timer? _debounce;
  bool _running = false;
  int? _lastSignature;

  Map<String, dynamic> _sensors = const <String, dynamic>{};
  Map<String, dynamic> _leaf = const <String, dynamic>{};
  Map<String, dynamic> _autoWater = const <String, dynamic>{};
  Map<String, dynamic> _pumps = const <String, dynamic>{};

  static AutoActionsEngine? _instance;

  /// Starts the engine once (idempotent).
  static AutoActionsEngine ensureStarted({
    required FirebaseDatabase database,
    bool debug = false,
  }) {
    _instance ??= AutoActionsEngine._(database: database, debug: debug)
      ..start();
    return _instance!;
  }

  void start() {
    _sensorsSub ??= _database
        .ref(FarmPayload.sensorsPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            _sensors = _toMap(event.snapshot.value);
            _scheduleEvaluate();
          },
          onError: (Object e, StackTrace s) {
            debugPrint('[AUTO] sensors stream error: $e\n$s');
          },
        );

    _leafSub ??= _database
        .ref(FarmPayload.leafPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            _leaf = _toMap(event.snapshot.value);
            _scheduleEvaluate();
          },
          onError: (Object e, StackTrace s) {
            debugPrint('[AUTO] leaf stream error: $e\n$s');
          },
        );

    _autoWaterSub ??= _database
        .ref(FarmPayload.autoWaterPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            _autoWater = _toMap(event.snapshot.value);
            _scheduleEvaluate();
          },
          onError: (Object e, StackTrace s) {
            debugPrint('[AUTO] auto_water stream error: $e\n$s');
          },
        );

    _pumpsSub ??= _database
        .ref(FarmPayload.pumpsPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            _pumps = _toMap(event.snapshot.value);
            _scheduleEvaluate();
          },
          onError: (Object e, StackTrace s) {
            debugPrint('[AUTO] pumps stream error: $e\n$s');
          },
        );

    if (_debug) {
      debugPrint('[AUTO] AutoActionsEngine started.');
    }
  }

  Future<void> dispose() async {
    await _sensorsSub?.cancel();
    await _leafSub?.cancel();
    await _autoWaterSub?.cancel();
    await _pumpsSub?.cancel();
    _sensorsSub = null;
    _leafSub = null;
    _autoWaterSub = null;
    _pumpsSub = null;
    _debounce?.cancel();
    _debounce = null;
  }

  void _scheduleEvaluate() {
    // Debounce bursts of updates (sensor + config + pumps changes).
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _evaluateIfNeeded);
  }

  Future<void> _evaluateIfNeeded() async {
    if (_running) return;

    final int? temp = _asInt(_sensors['temp']);
    final int? hum = _asInt(_sensors['hum']);
    final int? moist = _asInt(_sensors['moist']);

    final int? tempMin = _asInt(_autoWater['temp_min']);
    final int? tempMax = _asInt(_autoWater['temp_max']);
    final int? humMin = _asInt(_autoWater['hum_min']);
    final int? humMax = _asInt(_autoWater['hum_max']);
    final int? moistMin = _asInt(_autoWater['moist_min']);
    final int? moistMax = _asInt(_autoWater['moist_max']);

    final bool autoMode = (_pumps['auto'] as bool?) ?? false;
    final bool currentPumpOn = (_pumps['water'] as bool?) ?? false;

    // Not ready yet.
    if (temp == null ||
        hum == null ||
        moist == null ||
        tempMin == null ||
        tempMax == null ||
        humMin == null ||
        humMax == null ||
        moistMin == null ||
        moistMax == null) {
      return;
    }

    final String? leafStatus = _leaf['status']?.toString();

    final int signature = Object.hash(
      autoMode,
      currentPumpOn,
      temp,
      hum,
      moist,
      tempMin,
      tempMax,
      humMin,
      humMax,
      moistMin,
      moistMax,
      leafStatus,
    );

    if (_lastSignature == signature) {
      return;
    }

    _lastSignature = signature;
    _running = true;

    try {
      await AutoActionsScenario.runWaterScenario(
        database: _database,
        autoMode: autoMode,
        currentPumpOn: currentPumpOn,
        temp: temp,
        hum: hum,
        moist: moist,
        tempMin: tempMin,
        tempMax: tempMax,
        humMin: humMin,
        humMax: humMax,
        moistMin: moistMin,
        moistMax: moistMax,
        leafStatus: leafStatus,
        debug: _debug,
      );
    } catch (e, s) {
      debugPrint('[AUTO] runWaterScenario failed: $e\n$s');
    } finally {
      _running = false;
    }
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    final String text = value.toString();
    final int? parsedInt = int.tryParse(text);
    if (parsedInt != null) return parsedInt;
    final double? parsedDouble = double.tryParse(text);
    return parsedDouble?.round();
  }
}
