import 'package:firebase_database/firebase_database.dart';

import '../../features/firebase_data/models/farm_payload.dart';

enum AutoActionKind { water, fertilizer }

class AutoActionDecision {
  const AutoActionDecision({
    required this.kind,
    required this.desiredPumpOn,
    required this.shouldApplyPumpChange,
    required this.shouldWriteLog,
    required this.shouldSendNotification,
    required this.reason,
    required this.targetValue,
    required this.logTitle,
    required this.logMessage,
    required this.notificationTitle,
    required this.notificationMessage,
    required this.createdAt,
    required this.sensorsSnapshot,
    required this.leafStatus,
  });

  final AutoActionKind kind;
  final bool desiredPumpOn;
  final bool shouldApplyPumpChange;
  final bool shouldWriteLog;
  final bool shouldSendNotification;
  final String reason;
  final double? targetValue;
  final String logTitle;
  final String logMessage;
  final String notificationTitle;
  final String notificationMessage;
  final DateTime createdAt;
  final Map<String, dynamic> sensorsSnapshot;
  final String? leafStatus;

  static AutoActionDecision none({
    required AutoActionKind kind,
    required String reason,
    required DateTime createdAt,
    Map<String, dynamic> sensorsSnapshot = const <String, dynamic>{},
    String? leafStatus,
  }) {
    final String label = kind == AutoActionKind.water ? 'Water' : 'Fertilizer';
    return AutoActionDecision(
      kind: kind,
      desiredPumpOn: false,
      shouldApplyPumpChange: false,
      shouldWriteLog: false,
      shouldSendNotification: false,
      reason: reason,
      targetValue: null,
      logTitle: 'Auto $label idle',
      logMessage: 'No action required.',
      notificationTitle: 'Auto $label idle',
      notificationMessage: 'No action required.',
      createdAt: createdAt,
      sensorsSnapshot: sensorsSnapshot,
      leafStatus: leafStatus,
    );
  }

  Map<String, dynamic> toLogMap() {
    return <String, dynamic>{
      'time': createdAt.toUtc().toIso8601String(),
      'pump': kind == AutoActionKind.water ? 'Water' : 'Fertilizer',
      'action': desiredPumpOn ? 'ON' : 'OFF',
      'reason': reason,
      'target': targetValue,
      'title': logTitle,
      'message': logMessage,
      'state': sensorsSnapshot,
      'leaf_status': leafStatus,
    };
  }

  Map<String, dynamic> toNotificationMap() {
    return <String, dynamic>{
      'title': notificationTitle,
      'message': notificationMessage,
      'disease_name': kind == AutoActionKind.water
          ? 'Auto_Water'
          : 'Auto_Fertilizer',
      'next_upload': '',
      'is_read': false,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

class AutoActionsScenario {
  const AutoActionsScenario._();

  // Editable tuning values for the water scenario.
  static const double smallBonusFactor = 0.05;
  static const double mediumBonusFactor = 0.10;
  static const double highBonusFactor = 0.18;
  static const double humidAirReduceFactor = 0.08;

  static double normalTarget(int moistMin, int moistMax) {
    return (moistMin + moistMax) / 2;
  }

  static double smallBonus(int moistMin, int moistMax) {
    return (moistMax - moistMin) * smallBonusFactor;
  }

  static double mediumBonus(int moistMin, int moistMax) {
    return (moistMax - moistMin) * mediumBonusFactor;
  }

  static double highBonus(int moistMin, int moistMax) {
    return (moistMax - moistMin) * highBonusFactor;
  }

  static double moistureHumidAirReduce(int moistMin, int moistMax) {
    return (moistMax - moistMin) * humidAirReduceFactor;
  }

  static AutoActionDecision evaluateWater({
    required bool autoMode,
    required bool currentPumpOn,
    required int temp,
    required int hum,
    required int moist,
    required int tempMin,
    required int tempMax,
    required int humMin,
    required int humMax,
    required int moistMin,
    required int moistMax,
    String? leafStatus,
    DateTime? createdAt,
  }) {
    final DateTime now = createdAt ?? DateTime.now();
    final Map<String, dynamic> snapshot = <String, dynamic>{
      'temp': temp,
      'hum': hum,
      'moist': moist,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'hum_min': humMin,
      'hum_max': humMax,
      'moist_min': moistMin,
      'moist_max': moistMax,
    };

    if (!autoMode) {
      return AutoActionDecision.none(
        kind: AutoActionKind.water,
        reason: 'auto_mode_off',
        createdAt: now,
        sensorsSnapshot: snapshot,
        leafStatus: leafStatus,
      );
    }

    bool desiredPumpOn = currentPumpOn;
    bool shouldWriteLog = false;
    bool shouldSendNotification = false;
    String reason = 'soil_safe';
    String logTitle = 'Auto Water Idle';
    String logMessage = 'Soil moisture is within the safe range.';
    String notificationTitle = 'Auto Water';
    String notificationMessage = 'Soil moisture is within the safe range.';
    double? targetValue;

    if (moist >= moistMax) {
      desiredPumpOn = false;
      reason = 'emergency_stop';
      logTitle = 'Auto Water Stopped';
      logMessage = 'Moisture reached the upper safe limit.';
      notificationTitle = 'Auto Water Stopped';
      notificationMessage =
          'Watering stopped because moisture reached the safe limit.';
      shouldWriteLog = currentPumpOn;
      shouldSendNotification = currentPumpOn;
    } else if (moist < moistMin) {
      desiredPumpOn = true;

      if (temp > tempMax && hum < humMin) {
        reason = 'hot_and_dry_air';
        targetValue = moistMin + highBonus(moistMin, moistMax);
      } else if (temp > tempMax) {
        reason = 'hot_air';
        targetValue = moistMin + mediumBonus(moistMin, moistMax);
      } else if (hum < humMin) {
        reason = 'dry_air';
        targetValue = moistMin + smallBonus(moistMin, moistMax);
      } else if (temp < tempMin || hum > humMax) {
        reason = 'cold_or_humid_air';
        targetValue = moistMin + moistureHumidAirReduce(moistMin, moistMax);
      } else {
        reason = 'normal_climate';
        targetValue = normalTarget(moistMin, moistMax);
      }

      targetValue = _clampTarget(targetValue, moistMin, moistMax);
      logTitle = 'Auto Water Started';
      logMessage =
          'Watering started because moisture is below the safe range (target: ${targetValue.toStringAsFixed(1)}).';
      notificationTitle = 'Auto Water Started';
      notificationMessage =
          'Watering started because moisture is low. Current moist: $moist, target: ${targetValue.toStringAsFixed(1)}.';
      shouldWriteLog = !currentPumpOn;
      shouldSendNotification = !currentPumpOn;
    } else {
      desiredPumpOn = false;
      reason = 'soil_safe';
      logTitle = 'Auto Water Stopped';
      logMessage = 'Soil moisture is safe, so the pump stayed off.';
      notificationTitle = 'Auto Water';
      notificationMessage = 'Moisture is safe. Pump remains off.';
      shouldWriteLog = false;
      shouldSendNotification = false;
    }

    return AutoActionDecision(
      kind: AutoActionKind.water,
      desiredPumpOn: desiredPumpOn,
      shouldApplyPumpChange: desiredPumpOn != currentPumpOn,
      shouldWriteLog: shouldWriteLog,
      shouldSendNotification: shouldSendNotification,
      reason: reason,
      targetValue: targetValue,
      logTitle: logTitle,
      logMessage: logMessage,
      notificationTitle: notificationTitle,
      notificationMessage: notificationMessage,
      createdAt: now,
      sensorsSnapshot: snapshot,
      leafStatus: leafStatus,
    );
  }

  static AutoActionDecision evaluateFertilizer({
    required bool autoMode,
    required bool currentPumpOn,
    required int n,
    required int p,
    required int k,
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
    String? leafStatus,
    DateTime? createdAt,
  }) {
    final DateTime now = createdAt ?? DateTime.now();
    final Map<String, dynamic> snapshot = <String, dynamic>{
      'n': n,
      'p': p,
      'k': k,
      'n_min': nMin,
      'n_max': nMax,
      'p_min': pMin,
      'p_max': pMax,
      'k_min': kMin,
      'k_max': kMax,
      'leaf_goal': leafGoal,
    };

    return AutoActionDecision.none(
      kind: AutoActionKind.fertilizer,
      reason: autoMode ? 'scenario_empty' : 'auto_mode_off',
      createdAt: now,
      sensorsSnapshot: snapshot,
      leafStatus: leafStatus,
    );
  }

  static Future<AutoActionDecision> runWaterScenario({
    required FirebaseDatabase database,
    required bool autoMode,
    required bool currentPumpOn,
    required int temp,
    required int hum,
    required int moist,
    required int tempMin,
    required int tempMax,
    required int humMin,
    required int humMax,
    required int moistMin,
    required int moistMax,
    String? leafStatus,
    DateTime? createdAt,
  }) async {
    final AutoActionDecision decision = evaluateWater(
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
      createdAt: createdAt,
    );

    if (!autoMode) {
      return decision;
    }

    if (decision.shouldApplyPumpChange) {
      await database
          .ref('${FarmPayload.pumpsPath}/water')
          .set(decision.desiredPumpOn);
    }

    if (decision.shouldWriteLog) {
      final String logId =
          'auto_water_${decision.createdAt.microsecondsSinceEpoch}';
      await database
          .ref('${FarmPayload.autoLogsPath}/water/$logId')
          .set(decision.toLogMap());
    }

    if (decision.shouldSendNotification) {
      final String notificationId =
          'auto_water_${decision.createdAt.microsecondsSinceEpoch}';
      await database
          .ref('${FarmPayload.notificationItemsPath}/$notificationId')
          .set(decision.toNotificationMap());
      final countSnapshot = await database
          .ref(FarmPayload.unreadCountPath)
          .get();
      final currentUnread = (countSnapshot.value as int?) ?? 0;
      await database.ref(FarmPayload.unreadCountPath).set(currentUnread + 1);
    }

    return decision;
  }

  static Future<AutoActionDecision> runFertilizerScenario({
    required FirebaseDatabase database,
    required bool autoMode,
    required bool currentPumpOn,
    required int n,
    required int p,
    required int k,
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
    String? leafStatus,
    DateTime? createdAt,
  }) async {
    final AutoActionDecision decision = evaluateFertilizer(
      autoMode: autoMode,
      currentPumpOn: currentPumpOn,
      n: n,
      p: p,
      k: k,
      nMin: nMin,
      nMax: nMax,
      pMin: pMin,
      pMax: pMax,
      kMin: kMin,
      kMax: kMax,
      leafGoal: leafGoal,
      leafStatus: leafStatus,
      createdAt: createdAt,
    );

    // Fertilizer scenario intentionally stays empty until rules are finalized.
    return decision;
  }

  static double _clampTarget(double target, int minValue, int maxValue) {
    return target.clamp(minValue.toDouble(), maxValue.toDouble()).toDouble();
  }
}
