// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../../firebase_data/models/farm_payload.dart';
import '../../../core/services/firebase_streams.dart';
import '../../../core/localization/app_strings.dart';
import '../models/farm_notification.dart';

class NotificationsService {
  NotificationsService({required FirebaseDatabase database})
    : _database = database;

  final FirebaseDatabase _database;

  /// Add a new notification when disease is detected
  Future<void> addDiseaseNotification({
    required String diseaseName,
    required String nextUpload,
    DateTime? createdAt,
  }) async {
    try {
      final String id = const Uuid().v4().replaceAll('-', '').substring(0, 12);

      final String displayName = AppStrings.displayDiseaseName(diseaseName);

      final FarmNotification notification = FarmNotification(
        id: id,
        title: 'تم اكتشاف $displayName',
        message: 'تم اكتشاف $displayName على ورقة ${AppStrings.plantDefinite}',
        diseaseName: diseaseName,
        nextUpload: nextUpload,
        isRead: false,
        createdAt: createdAt ?? DateTime.now(),
        type: FarmNotification.typeDisease,
      );

      print(
        '[NOTIFICATIONS_SERVICE] Adding disease notification: $diseaseName',
      );

      // Write notification
      await _database
          .ref('${FarmPayload.notificationItemsPath}/notif_$id')
          .set(notification.toMap());

      // Increment unread count
      await _incrementUnreadCount();

      print('[NOTIFICATIONS_SERVICE] Disease notification added successfully');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error adding notification: $e');
      rethrow;
    }
  }

  /// Remind the user to re-upload a leaf image on the scheduled day.
  Future<void> addReuploadReminderNotification({
    required DateTime reuploadDueAt,
  }) async {
    try {
      final String id = const Uuid().v4().replaceAll('-', '').substring(0, 12);

      final FarmNotification notification = FarmNotification(
        id: id,
        title: 'تذكير برفع صورة اليوم',
        message:
            'حان موعد إعادة رفع صورة الورقة للكشف عن الأمراض. يرجى التقاط صورة جديدة اليوم.',
        diseaseName: '',
        nextUpload: '',
        isRead: false,
        createdAt: reuploadDueAt,
        type: FarmNotification.typeReuploadReminder,
      );

      print(
        '[NOTIFICATIONS_SERVICE] Adding re-upload reminder for ${reuploadDueAt.toIso8601String()}',
      );

      await _database
          .ref('${FarmPayload.notificationItemsPath}/notif_$id')
          .set(notification.toMap());

      await _incrementUnreadCount();

      print('[NOTIFICATIONS_SERVICE] Re-upload reminder added successfully');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error adding re-upload reminder: $e');
      rethrow;
    }
  }

  /// Clears [next_upload] on disease notifications after the reminder fires.
  Future<void> clearDiseaseNextUploadFields() async {
    try {
      final DataSnapshot snapshot = await _database
          .ref(FarmPayload.notificationItemsPath)
          .get();
      if (!snapshot.exists) return;

      final Map<dynamic, dynamic> raw =
          snapshot.value as Map<dynamic, dynamic>;
      for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(entry.value);
        final String nextUpload = map['next_upload'] as String? ?? '';
        if (nextUpload.isEmpty) continue;

        final String type = (map['type'] as String? ?? '').toLowerCase();
        final bool isDisease = type == FarmNotification.typeDisease ||
            (type.isEmpty &&
                (map['disease_name'] as String? ?? '').isNotEmpty &&
                (map['disease_name'] as String? ?? '').toLowerCase() !=
                    'user_signup');
        if (!isDisease) continue;

        await _database
            .ref('${FarmPayload.notificationItemsPath}/${entry.key}')
            .update(<String, dynamic>{'next_upload': ''});
      }
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error clearing next_upload fields: $e');
    }
  }

  /// Delete all notifications and reset unread count.
  Future<void> deleteAllNotifications() async {
    try {
      final snapshot = await _database
          .ref(FarmPayload.notificationItemsPath)
          .get();
      if (!snapshot.exists) {
        await _database.ref(FarmPayload.unreadCountPath).set(0);
        return;
      }

      // Remove all notification items and reset unread counter.
      await _database.ref(FarmPayload.notificationItemsPath).remove();
      await _database.ref(FarmPayload.unreadCountPath).set(0);

      print('[NOTIFICATIONS_SERVICE] All notifications deleted');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Use centralized display mapping in `AppStrings`.

  Future<void> markAsUnread(String notificationId) async {
    try {
      print('[NOTIFICATIONS_SERVICE] Marking $notificationId as unread');

      final DataSnapshot event = await _database
          .ref(
            '${FarmPayload.notificationItemsPath}/notif_$notificationId/is_read',
          )
          .get();
      final bool wasRead = event.value as bool? ?? false;
      if (!wasRead) {
        return;
      }

      await _database
          .ref('${FarmPayload.notificationItemsPath}/notif_$notificationId')
          .update(<String, dynamic>{'is_read': false});

      // Increment unread count
      final snapshot = await _database.ref(FarmPayload.unreadCountPath).get();
      final currentCount = (snapshot.value as int?) ?? 0;
      await _database.ref(FarmPayload.unreadCountPath).set(currentCount + 1);

      print('[NOTIFICATIONS_SERVICE] Notification marked as unread');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error marking as unread: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _database
          .ref(FarmPayload.notificationItemsPath)
          .get();
      if (!snapshot.exists) {
        await _database.ref(FarmPayload.unreadCountPath).set(0);
        return;
      }

      final Map<dynamic, dynamic> raw = snapshot.value as Map<dynamic, dynamic>;
      for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
        await _database
            .ref('${FarmPayload.notificationItemsPath}/${entry.key}')
            .update(<String, dynamic>{'is_read': true});
      }
      await _database.ref(FarmPayload.unreadCountPath).set(0);
      await _database.ref(FarmPayload.unreadCountPath).set(0);
      print('[NOTIFICATIONS_SERVICE] All notifications marked as read');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error marking all as read: $e');
      rethrow;
    }
  }

  /// Increment unread count
  Future<void> _incrementUnreadCount() async {
    try {
      final snapshot = await _database.ref(FarmPayload.unreadCountPath).get();
      final currentCount = (snapshot.value as int?) ?? 0;
      await _database.ref(FarmPayload.unreadCountPath).set(currentCount + 1);
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error incrementing unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('[NOTIFICATIONS_SERVICE] Marking $notificationId as read');

      final DataSnapshot event = await _database
          .ref(
            '${FarmPayload.notificationItemsPath}/notif_$notificationId/is_read',
          )
          .get();
      final bool wasRead = event.value as bool? ?? false;
      if (wasRead) {
        return;
      }

      await _database
          .ref('${FarmPayload.notificationItemsPath}/notif_$notificationId')
          .update(<String, dynamic>{'is_read': true});

      final snapshot = await _database.ref(FarmPayload.unreadCountPath).get();
      final currentCount = (snapshot.value as int?) ?? 0;
      if (currentCount > 0) {
        await _database.ref(FarmPayload.unreadCountPath).set(currentCount - 1);
      }

      print('[NOTIFICATIONS_SERVICE] Notification marked as read');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error marking as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('[NOTIFICATIONS_SERVICE] Deleting $notificationId');

      // Check if was unread before deleting
      final snapshot = await _database
          .ref(
            '${FarmPayload.notificationItemsPath}/notif_$notificationId/is_read',
          )
          .get();
      final wasRead = snapshot.value as bool? ?? true;

      await _database
          .ref('${FarmPayload.notificationItemsPath}/notif_$notificationId')
          .remove();

      // Decrement unread count if it was unread
      if (!wasRead) {
        final countSnapshot = await _database
            .ref(FarmPayload.unreadCountPath)
            .get();
        final currentCount = (countSnapshot.value as int?) ?? 0;
        if (currentCount > 0) {
          await _database
              .ref(FarmPayload.unreadCountPath)
              .set(currentCount - 1);
        }
      }

      print('[NOTIFICATIONS_SERVICE] Notification deleted');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get real-time stream of all notifications
  Stream<List<FarmNotification>> getNotificationsStream() {
    return FirebaseStreams.notificationItemsStream.map((event) {
      if (!event.snapshot.exists) {
        return <FarmNotification>[];
      }

      final Map<dynamic, dynamic> raw =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<FarmNotification> notifications = raw.entries
          .map((e) {
            final id = e.key.toString().replaceFirst('notif_', '');
            final map = Map<String, dynamic>.from(e.value);
            return FarmNotification.fromMap(id, map);
          })
          .where((FarmNotification n) => n.isDisplayable)
          .toList();

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  /// Get real-time stream of unread count
  Stream<int> getUnreadCountStream() {
    return FirebaseStreams.unreadCountStream.map(
      (event) => (event.snapshot.value as int?) ?? 0,
    );
  }
}
