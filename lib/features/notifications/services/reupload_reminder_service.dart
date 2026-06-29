// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/services/firebase_streams.dart';
import '../../firebase_data/models/farm_payload.dart';
import 'notifications_service.dart';

/// Sends a one-time re-upload reminder when [leaf/reupload_at] is due.
///
/// If the app was closed on the due day, the reminder is sent on next open with
/// [created_at] set to the original due date so the list stays chronologically
/// correct.
class ReuploadReminderService {
  ReuploadReminderService({
    required FirebaseDatabase database,
    required NotificationsService notificationsService,
  }) : _database = database,
       _notificationsService = notificationsService;

  static const String _sentForKey = 'reupload_reminder_sent_for';

  final FirebaseDatabase _database;
  final NotificationsService _notificationsService;

  StreamSubscription<DatabaseEvent>? _leafSubscription;
  bool _checkInProgress = false;

  void start() {
    _leafSubscription?.cancel();
    _leafSubscription = FirebaseStreams.leafStream.listen((_) {
      unawaited(_checkAndNotify());
    });
    unawaited(_checkAndNotify());
  }

  Future<void> dispose() async {
    await _leafSubscription?.cancel();
    _leafSubscription = null;
  }

  Future<void> _checkAndNotify() async {
    if (_checkInProgress) return;
    if (!AppRuntimeConfig.pushNotifications.value) return;

    _checkInProgress = true;
    try {
      final DataSnapshot snapshot = await _database
          .ref('${FarmPayload.leafPath}/reupload_at')
          .get();
      final String reuploadAt = snapshot.value?.toString().trim() ?? '';
      if (reuploadAt.isEmpty) return;

      final DateTime? dueAt = DateTime.tryParse(reuploadAt);
      if (dueAt == null) {
        print('[REUPLOAD_REMINDER] Invalid reupload_at: $reuploadAt');
        return;
      }

      if (!_isDue(dueAt)) return;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? alreadySentFor = prefs.getString(_sentForKey);
      if (alreadySentFor == reuploadAt) {
        await _clearReuploadState();
        return;
      }

      await _notificationsService.addReuploadReminderNotification(
        reuploadDueAt: dueAt,
      );
      await prefs.setString(_sentForKey, reuploadAt);
      await _clearReuploadState();

      print('[REUPLOAD_REMINDER] Reminder sent for due date: $reuploadAt');
    } catch (e) {
      print('[REUPLOAD_REMINDER] Error: $e');
    } finally {
      _checkInProgress = false;
    }
  }

  Future<void> _clearReuploadState() async {
    await _database.ref('${FarmPayload.leafPath}/reupload_at').set('');
    await _notificationsService.clearDiseaseNextUploadFields();
  }

  static bool _isDue(DateTime dueAt) {
    final DateTime dueLocal = dueAt.toLocal();
    final DateTime now = DateTime.now();
    final DateTime dueDate = DateTime(
      dueLocal.year,
      dueLocal.month,
      dueLocal.day,
    );
    final DateTime today = DateTime(now.year, now.month, now.day);
    return !dueDate.isAfter(today);
  }
}
