import 'package:firebase_database/firebase_database.dart';

/// Monitors pump state changes locally (ESP32 persists logs to Firebase).
class PumpChangeLogger {
  PumpChangeLogger({required FirebaseDatabase database})
    : _database = database;

  final FirebaseDatabase _database;

  final Map<String, bool> _previousPumpStates = <String, bool>{};

  void startMonitoring(String pumpsPath) {
    _database.ref(pumpsPath).onValue.listen((DatabaseEvent event) {
      if (!event.snapshot.exists) return;

      final Map<dynamic, dynamic> raw =
          event.snapshot.value as Map<dynamic, dynamic>;
      final Map<String, bool> currentState = <String, bool>{};

      for (final key in ['water', 'fert1', 'fert2', 'auto']) {
        currentState[key] = (raw[key] as bool?) ?? false;
      }

      currentState.forEach((pump, isActive) {
        final bool wasActive = _previousPumpStates[pump] ?? false;
        if (wasActive != isActive) {
          _logPumpChange(pump, isActive);
        }
      });

      _previousPumpStates.addAll(currentState);
    });
  }

  void _logPumpChange(String pump, bool isActive) {
    // Pump history is stored under extra/logs by the ESP32.
  }
}
