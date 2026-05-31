import 'package:firebase_database/firebase_database.dart';
import '../../features/notifications/services/notifications_service.dart';

/// Logs pump state changes and sends notifications.
///
/// Monitors pump configuration and triggers notifications when pump states
/// (water, fert1, fert2, auto) change.
class PumpChangeLogger {
  PumpChangeLogger({
    required FirebaseDatabase database,
    required NotificationsService notificationsService,
  }) : _database = database,
       _notificationsService = notificationsService;

  final FirebaseDatabase _database;
  final NotificationsService _notificationsService;

  /// Previous pump states to detect changes.
  final Map<String, bool> _previousPumpStates = <String, bool>{};

  /// Start monitoring pump changes.
  void startMonitoring(String pumpsPath) {
    _database.ref(pumpsPath).onValue.listen((DatabaseEvent event) {
      if (!event.snapshot.exists) return;

      final Map<dynamic, dynamic> raw =
          event.snapshot.value as Map<dynamic, dynamic>;
      final Map<String, bool> currentState = <String, bool>{};

      // Extract pump states
      for (final key in ['water', 'fert1', 'fert2', 'auto']) {
        currentState[key] = (raw[key] as bool?) ?? false;
      }

      // Detect and log changes
      currentState.forEach((pump, isActive) {
        final bool wasActive = _previousPumpStates[pump] ?? false;
        if (wasActive != isActive) {
          _logPumpChange(pump, isActive);
        }
      });

      _previousPumpStates.addAll(currentState);
    });
  }

  /// Log individual pump state change.
  Future<void> _logPumpChange(String pump, bool isActive) async {
    final String pumpName = _displayPumpName(pump);
    final String action = isActive ? 'تفعيل' : 'إيقاف';
    final String title = '$pumpName: $action';
    final String message = 'تم ${isActive ? 'تفعيل' : 'إيقاف'} مضخة $pumpName';

    try {
      await _notificationsService.addLogNotification(
        title: title,
        message: message,
        logType: 'pump_change_$pump',
      );
    } catch (e) {
      print('[PUMP_CHANGE_LOGGER] Error logging pump change: $e');
    }
  }

  String _displayPumpName(String pump) {
    switch (pump.toLowerCase()) {
      case 'water':
        return 'مضخة المياه';
      case 'fert1':
        return 'مضخة السماد 1';
      case 'fert2':
        return 'مضخة السماد 2';
      case 'auto':
        return 'الوضع التلقائي';
      default:
        return pump;
    }
  }
}
