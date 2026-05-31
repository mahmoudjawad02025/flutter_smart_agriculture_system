// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_data/models/farm_payload.dart';
import '../../../core/config/app_runtime_config.dart';
import 'notifications_service.dart';

class SensorThresholdMonitorService {
  SensorThresholdMonitorService({
    required FirebaseDatabase database,
    required NotificationsService notificationsService,
  }) : _database = database,
       _notificationsService = notificationsService;

  final FirebaseDatabase _database;
  final NotificationsService _notificationsService;

  StreamSubscription<DatabaseEvent>? _nitrogenSubscription;
  StreamSubscription<DatabaseEvent>? _phosphorusSubscription;
  StreamSubscription<DatabaseEvent>? _potassiumSubscription;
  StreamSubscription<DatabaseEvent>? _moistureSubscription;
  StreamSubscription<DatabaseEvent>? _tempSubscription;
  StreamSubscription<DatabaseEvent>? _humSubscription;
  StreamSubscription<DatabaseEvent>? _autoWaterConfigSubscription;

  // Track last notified value to avoid duplicate notifications
  int? _lastNitrogenNotified;
  int? _lastPhosphorusNotified;
  int? _lastPotassiumNotified;
  int? _lastMoistureNotified;
  int? _lastTempNotified;
  int? _lastHumNotified;

  // Cache for moisture thresholds from Firebase
  int _moistureMinThreshold = 30;
  int _moistureMaxThreshold = 65;

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final int? asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final num? asNum = num.tryParse(trimmed);
      return asNum?.round();
    }
    return _asInt(value.toString());
  }

  /// Start monitoring sensor thresholds
  void startMonitoring() {
    print('[SENSOR_MONITOR] Starting sensor threshold monitoring');
    _monitorNitrogen();
    _monitorPhosphorus();
    _monitorPotassium();
    _monitorAutoWaterConfig(); // Must come first to load thresholds
    _monitorMoisture();
    _monitorTemp();
    _monitorHum();
  }

  /// Stop monitoring sensor thresholds
  void stopMonitoring() {
    print('[SENSOR_MONITOR] Stopping sensor threshold monitoring');
    _nitrogenSubscription?.cancel();
    _phosphorusSubscription?.cancel();
    _potassiumSubscription?.cancel();
    _moistureSubscription?.cancel();
    _tempSubscription?.cancel();
    _humSubscription?.cancel();
    _autoWaterConfigSubscription?.cancel();
  }

  void _monitorTemp() {
    _tempSubscription = _database
        .ref('${FarmPayload.sensorsPath}/temp')
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] temp event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? tempValue = _asInt(value);
              if (tempValue != null) {
                print(
                  '[SENSOR_MONITOR] Checking temp $tempValue against thresholds (min=${AppRuntimeConfig.tempMin.value}, max=${AppRuntimeConfig.tempMax.value})',
                );
                _checkThreshold(
                  'temperature',
                  'temp',
                  tempValue,
                  AppRuntimeConfig.tempMin.value,
                  AppRuntimeConfig.tempMax.value,
                  () => _lastTempNotified,
                  (val) => _lastTempNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring temp: $error');
          },
        );
  }

  void _monitorHum() {
    _humSubscription = _database
        .ref('${FarmPayload.sensorsPath}/hum')
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] hum event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? humValue = _asInt(value);
              if (humValue != null) {
                print(
                  '[SENSOR_MONITOR] Checking hum $humValue against thresholds (min=${AppRuntimeConfig.humMin.value}, max=${AppRuntimeConfig.humMax.value})',
                );
                _checkThreshold(
                  'humidity',
                  'hum',
                  humValue,
                  AppRuntimeConfig.humMin.value,
                  AppRuntimeConfig.humMax.value,
                  () => _lastHumNotified,
                  (val) => _lastHumNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring hum: $error');
          },
        );
  }

  void _monitorNitrogen() {
    _nitrogenSubscription = _database
        .ref(FarmPayload.nitrogenPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] nitrogen event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? nitrogenValue = _asInt(value);
              if (nitrogenValue != null) {
                _checkThreshold(
                  'nitrogen',
                  'N',
                  nitrogenValue,
                  AppRuntimeConfig.nMin.value,
                  AppRuntimeConfig.nMax.value,
                  () => _lastNitrogenNotified,
                  (val) => _lastNitrogenNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring nitrogen: $error');
          },
        );
  }

  void _monitorPhosphorus() {
    _phosphorusSubscription = _database
        .ref('${FarmPayload.sensorsPath}/p')
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] phosphorus event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? phosphorusValue = _asInt(value);
              if (phosphorusValue != null) {
                _checkThreshold(
                  'phosphorus',
                  'P',
                  phosphorusValue,
                  AppRuntimeConfig.pMin.value,
                  AppRuntimeConfig.pMax.value,
                  () => _lastPhosphorusNotified,
                  (val) => _lastPhosphorusNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring phosphorus: $error');
          },
        );
  }

  void _monitorPotassium() {
    _potassiumSubscription = _database
        .ref('${FarmPayload.sensorsPath}/k')
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] potassium event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? potassiumValue = _asInt(value);
              if (potassiumValue != null) {
                _checkThreshold(
                  'potassium',
                  'K',
                  potassiumValue,
                  AppRuntimeConfig.kMin.value,
                  AppRuntimeConfig.kMax.value,
                  () => _lastPotassiumNotified,
                  (val) => _lastPotassiumNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring potassium: $error');
          },
        );
  }

  void _monitorAutoWaterConfig() {
    _autoWaterConfigSubscription = _database
        .ref(FarmPayload.autoWaterPath)
        .onValue
        .listen(
          (DatabaseEvent event) {
            print(
              '[SENSOR_MONITOR] auto_water config event: ${event.snapshot.value}',
            );
            final dynamic value = event.snapshot.value;
            if (value is Map) {
              final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(
                value,
              );

              final int? minVal = _asInt(map['moist_min']);
              final int? maxVal = _asInt(map['moist_max']);

              if (minVal != null) {
                _moistureMinThreshold = minVal;
                print(
                  '[SENSOR_MONITOR] Updated moisture min threshold: $minVal',
                );
              }
              if (maxVal != null) {
                _moistureMaxThreshold = maxVal;
                print(
                  '[SENSOR_MONITOR] Updated moisture max threshold: $maxVal',
                );
              }
            }
          },
          onError: (error) {
            print(
              '[SENSOR_MONITOR] Error monitoring auto_water config: $error',
            );
          },
        );
  }

  void _monitorMoisture() {
    _moistureSubscription = _database
        .ref('${FarmPayload.sensorsPath}/moist')
        .onValue
        .listen(
          (DatabaseEvent event) {
            print('[SENSOR_MONITOR] moisture event: ${event.snapshot.value}');
            final dynamic value = event.snapshot.value;
            if (value != null) {
              final int? moistureValue = _asInt(value);
              if (moistureValue != null) {
                print(
                  '[SENSOR_MONITOR] Checking moisture $moistureValue against thresholds (min=$_moistureMinThreshold, max=$_moistureMaxThreshold)',
                );
                _checkThreshold(
                  'moisture',
                  'Moist',
                  moistureValue,
                  _moistureMinThreshold,
                  _moistureMaxThreshold,
                  () => _lastMoistureNotified,
                  (val) => _lastMoistureNotified = val,
                );
              }
            }
          },
          onError: (error) {
            print('[SENSOR_MONITOR] Error monitoring moisture: $error');
          },
        );
  }

  /// Check if sensor value is near threshold (min +5 / max -5)
  void _checkThreshold(
    String sensorName,
    String sensorCode,
    int currentValue,
    int minThreshold,
    int maxThreshold,
    int? Function() getLastNotified,
    void Function(int) setLastNotified,
  ) {
    const int buffer = 5;
    bool shouldNotify = false;
    String thresholdType = '';

    // Notify only when value is within the buffer inside the safe range:
    // - near minimum: min <= value <= min + buffer
    // - near maximum: max - buffer <= value <= max
    if (currentValue >= minThreshold && currentValue <= minThreshold + buffer) {
      final lastNotified = getLastNotified();
      if (lastNotified == null || (currentValue - lastNotified).abs() >= 2) {
        shouldNotify = true;
        thresholdType = 'min';
      }
    }
    // Check if near maximum inside range
    else if (currentValue <= maxThreshold &&
        currentValue >= maxThreshold - buffer) {
      final lastNotified = getLastNotified();
      if (lastNotified == null || (currentValue - lastNotified).abs() >= 2) {
        shouldNotify = true;
        thresholdType = 'max';
      }
    }

    if (shouldNotify) {
      print(
        '[SENSOR_MONITOR] Threshold alert for $sensorName: $currentValue (near $thresholdType)',
      );
      setLastNotified(currentValue);
      _notificationsService
          .addSensorThresholdNotification(
            sensorName: sensorCode,
            sensorValue: currentValue,
            thresholdType: thresholdType,
          )
          .then((_) {
            print('[SENSOR_MONITOR] Notification written for $sensorName');
          })
          .catchError((e) {
            print(
              '[SENSOR_MONITOR] Error writing notification for $sensorName: $e',
            );
          });
    }
  }
}
