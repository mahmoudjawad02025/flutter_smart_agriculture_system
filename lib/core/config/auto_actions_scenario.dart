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
    final String label = kind == AutoActionKind.water ? 'الري' : 'التسميد';
    return AutoActionDecision(
      kind: kind,
      desiredPumpOn: false,
      shouldApplyPumpChange: false,
      shouldWriteLog: false,
      shouldSendNotification: false,
      reason: reason,
      targetValue: null,
      logTitle: 'النظام التلقائي ($label) - خامل',
      logMessage: 'لا يلزم أي إجراء.',
      notificationTitle: 'النظام التلقائي ($label)',
      notificationMessage: 'لا يوجد إجراء مطلوب.',
      createdAt: createdAt,
      sensorsSnapshot: sensorsSnapshot,
      leafStatus: leafStatus,
    );
  }

  Map<String, dynamic> toLogMap() {
    // Minimal log format: only record timestamp, pump name and action.
    return <String, dynamic>{
      'time': createdAt.toUtc().toIso8601String(),
      'pump': kind == AutoActionKind.water ? 'Water' : 'Fertilizer',
      'action': desiredPumpOn ? 'ON' : 'OFF',
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

  // ============================================================================
  // TUNABLE PARAMETERS - Edit these to adjust watering behavior
  // ============================================================================

  /// Small bonus: used when dry air (slight water increase)
  static const double smallBonusFactor = 0.05;

  /// Medium bonus: used when hot air (moderate water increase)
  static const double mediumBonusFactor = 0.10;

  /// High bonus: used when hot and dry air (aggressive water increase)
  static const double highBonusFactor = 0.15;

  /// Reduce water target when cold or humid (to prevent overwatering)
  static const double humidAirReduceFactor = 0.10;

  // ============================================================================
  // WATER SCENARIO - Helper functions
  // ============================================================================

  /// Determines if water pump should START
  /// Returns true when soil moisture drops below minimum threshold
  static bool shouldStartWaterPump({
    required int moist,
    required int moistMin,
  }) {
    return moist < moistMin;
  }

  /// Determines if water pump should STOP
  /// Stops when moisture reaches target OR exceeds maximum
  /// Target adjusts based on temperature/humidity conditions
  static bool shouldStopWaterPump({
    required int moist,
    required int moistMax,
    required double targetValue,
    required bool currentPumpOn,
  }) {
    // Emergency stop: moisture exceeded maximum safe level
    if (moist >= moistMax) {
      return true;
    }

    // Normal stop: moisture reached target value (affected by temp/hum)
    if (currentPumpOn && moist >= targetValue) {
      return true;
    }

    return false;
  }

  /// Calculates the target moisture level based on environmental conditions
  /// - Hot & Dry: Increase target aggressively (high bonus)
  /// - Hot: Increase target moderately (medium bonus)
  /// - Dry: Increase target slightly (small bonus)
  /// - Cold/Humid: Decrease target (reduce bonus)
  /// - Normal: Middle of safe range
  static double calculateWaterTarget({
    required int moistMin,
    required int moistMax,
    required int temp,
    required int hum,
    required int tempMin,
    required int tempMax,
    required int humMin,
    required int humMax,
  }) {
    // Base target is 70% into the safe range
    final double base = normalTarget(moistMin, moistMax);

    // Hot + Dry = aggressive watering (high bonus applied to base)
    if (temp > tempMax && hum < humMin) {
      return base + highBonus(moistMin, moistMax);
    }

    // Just Hot = moderate watering (medium bonus applied to base)
    if (temp > tempMax) {
      return base + mediumBonus(moistMin, moistMax);
    }

    // Just Dry = slight watering (small bonus applied to base)
    if (hum < humMin) {
      return base + smallBonus(moistMin, moistMax);
    }

    // Cold or Humid = reduce watering need (subtract from base)
    if (temp < tempMin || hum > humMax) {
      return base - moistureHumidAirReduce(moistMin, moistMax);
    }

    // Normal conditions = base (70% of range)
    return base;
  }

  // ============================================================================
  // HELPER CALCULATION FUNCTIONS
  // ============================================================================

  static double normalTarget(int moistMin, int moistMax) {
    return moistMin.toDouble() + 0.70 * (moistMax - moistMin);
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

  // ============================================================================
  // MAIN EVALUATION FUNCTION
  // ============================================================================

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

    // Auto mode disabled - no action
    if (!autoMode) {
      return AutoActionDecision.none(
        kind: AutoActionKind.water,
        reason: 'auto_mode_off',
        createdAt: now,
        sensorsSnapshot: snapshot,
        leafStatus: leafStatus,
      );
    }

    // Calculate target moisture based on current conditions
    // This target will be used to determine when to stop watering
    double targetValue = calculateWaterTarget(
      moistMin: moistMin,
      moistMax: moistMax,
      temp: temp,
      hum: hum,
      tempMin: tempMin,
      tempMax: tempMax,
      humMin: humMin,
      humMax: humMax,
    );
    targetValue = _clampTarget(targetValue, moistMin, moistMax);

    bool desiredPumpOn = currentPumpOn;
    bool shouldWriteLog = false;
    bool shouldSendNotification = false;
    String reason = 'soil_safe';
    String logTitle = 'النظام التلقائي (الري) - خامل';
    String logMessage = 'رطوبة التربة ضمن النطاق الآمن.';
    String notificationTitle = 'النظام التلقائي (الري)';
    String notificationMessage = 'رطوبة التربة ضمن النطاق الآمن.';

    // STOP PUMP: Check if pump should stop based on target value
    if (shouldStopWaterPump(
      moist: moist,
      moistMax: moistMax,
      targetValue: targetValue,
      currentPumpOn: currentPumpOn,
    )) {
      desiredPumpOn = false;

      if (moist >= moistMax) {
        // Emergency: reached max moisture
        reason = 'emergency_stop';
        logTitle = 'تم إيقاف الري التلقائي';
        logMessage = 'تم إيقاف الري لأن الرطوبة وصلت إلى الحد الأعلى الآمن.';
        notificationTitle = 'تم إيقاف الري التلقائي';
        notificationMessage =
            'توقف الري لأن الرطوبة وصلت إلى الحد الآمن الأعلى.';
      } else {
        // Normal stop: reached target moisture
        reason = 'soil_safe';
        logTitle = 'تم إيقاف الري التلقائي';
        logMessage =
            'رطوبة التربة وصلت للهدف (${targetValue.toStringAsFixed(1)})، تم إيقاف المضخة.';
        notificationTitle = 'تم إيقاف الري التلقائي';
        notificationMessage = 'الرطوبة وصلت للهدف. رطوبة آمنة الآن.';
      }

      shouldWriteLog = currentPumpOn; // Only log if pump state changed
      shouldSendNotification = currentPumpOn;
    }
    // START PUMP: When moisture is below minimum
    else if (shouldStartWaterPump(moist: moist, moistMin: moistMin)) {
      desiredPumpOn = true;

      // Set reason based on climate (determines why target is what it is)
      if (temp > tempMax && hum < humMin) {
        reason = 'hot_and_dry_air';
      } else if (temp > tempMax) {
        reason = 'hot_air';
      } else if (hum < humMin) {
        reason = 'dry_air';
      } else if (temp < tempMin || hum > humMax) {
        reason = 'cold_or_humid_air';
      } else {
        reason = 'normal_climate';
      }

      logTitle = 'بدأ الري التلقائي';
      logMessage =
          'تم بدء الري لأن الرطوبة أقل من النطاق الآمن (الهدف: ${targetValue.toStringAsFixed(1)}).';
      notificationTitle = 'بدأ الري التلقائي';
      notificationMessage =
          'تم بدء الري لأن الرطوبة منخفضة. الرطوبة الحالية: $moist، الهدف: ${targetValue.toStringAsFixed(1)}.';

      shouldWriteLog = !currentPumpOn; // Only log if pump state changed
      shouldSendNotification = !currentPumpOn;
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

  // ============================================================================
  // FERTILIZER SCENARIO - Currently EMPTY (to be implemented)
  // ============================================================================

  /// Evaluates fertilizer needs
  /// This scenario is intentionally empty until requirements are finalized
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

    // Placeholder: No fertilizer action implemented yet
    return AutoActionDecision.none(
      kind: AutoActionKind.fertilizer,
      reason: autoMode ? 'scenario_empty' : 'auto_mode_off',
      createdAt: now,
      sensorsSnapshot: snapshot,
      leafStatus: leafStatus,
    );
  }

  // ============================================================================
  // EXECUTION FUNCTIONS - Perform actual actions on Firebase
  // ============================================================================

  /// Runs the water pump scenario:
  /// 1. Evaluates current conditions
  /// 2. Updates pump state if needed
  /// 3. Writes logs to Firebase
  /// 4. Sends notifications
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
    bool debug = false,
  }) async {
    // Step 1: Evaluate water conditions
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
      // When auto mode is disabled we do not write logs.
      return decision;
    }

    // Step 2: Update pump state if needed
    if (decision.shouldApplyPumpChange) {
      await database
          .ref('${FarmPayload.pumpsPath}/water')
          .set(decision.desiredPumpOn);
    }

    // Step 3: Write log entry
    // Log writes are now centralized by `PumpChangeLogger` which listens to
    // the pumps root and records ON/OFF events. Avoid writing auto logs here
    // to prevent duplication.

    // Step 4: Send notification
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

  /// Runs the fertilizer pump scenario
  /// Currently a placeholder - no actions performed
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
    // Evaluate fertilizer scenario (currently empty)
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

    // TODO: Implement fertilizer scenario logic here
    return decision;
  }

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  /// Clamps the target value within safe min/max range
  static double _clampTarget(double target, int minValue, int maxValue) {
    return target.clamp(minValue.toDouble(), maxValue.toDouble()).toDouble();
  }
}
