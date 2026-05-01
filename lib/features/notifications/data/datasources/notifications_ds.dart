// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_cucumber_agriculture_system/features/notifications/data/models/farm_notification_model.dart';

class NotificationsService {
  NotificationsService({required FirebaseDatabase database})
    : _database = database;

  final FirebaseDatabase _database;
  static const String _notificationsPath =
      'smart_cucumber_agriculture/notifications';
  static const String _itemsPath = '$_notificationsPath/items';

  /// Add a new notification when disease is detected
  Future<void> addDiseaseNotification({
    required String diseaseName,
    required String nextUpload,
    DateTime? createdAt,
  }) async {
    try {
      final String id = const Uuid().v4().replaceAll('-', '').substring(0, 12);

      final FarmNotification notification = FarmNotification(
        id: id,
        title: 'Disease Detected',
        message: '$diseaseName detected on your cucumber leaf',
        diseaseName: diseaseName,
        nextUpload: nextUpload,
        isRead: false,
        createdAt: createdAt ?? DateTime.now(),
      );

      print(
        '[NOTIFICATIONS_SERVICE] Adding disease notification: $diseaseName',
      );

      // Write notification
      await _database.ref('$_itemsPath/notif_$id').set(notification.toMap());

      // Increment unread count
      await _incrementUnreadCount();

      print('[NOTIFICATIONS_SERVICE] Disease notification added successfully');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error adding notification: $e');
      rethrow;
    }
  }

  Future<void> markAsUnread(String notificationId) async {
    try {
      print('[NOTIFICATIONS_SERVICE] Marking $notificationId as unread');

      final DataSnapshot event = await _database
          .ref('$_itemsPath/notif_$notificationId/is_read')
          .get();
      final bool wasRead = event.value as bool? ?? false;
      if (!wasRead) {
        return;
      }

      await _database.ref('$_itemsPath/notif_$notificationId').update(
        <String, dynamic>{'is_read': false},
      );

      final snapshot = await _database
          .ref('$_notificationsPath/unread_count')
          .get();
      final currentCount = (snapshot.value as int?) ?? 0;
      await _database
          .ref('$_notificationsPath/unread_count')
          .set(currentCount + 1);

      print('[NOTIFICATIONS_SERVICE] Notification marked as unread');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error marking as unread: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _database.ref(_itemsPath).get();
      if (!snapshot.exists) {
        await _database.ref('$_notificationsPath/unread_count').set(0);
        return;
      }

      final Map<dynamic, dynamic> raw = snapshot.value as Map<dynamic, dynamic>;
      for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
        await _database.ref('$_itemsPath/${entry.key}').update(
          <String, dynamic>{'is_read': true},
        );
      }

      await _database.ref('$_notificationsPath/unread_count').set(0);
      print('[NOTIFICATIONS_SERVICE] All notifications marked as read');
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error marking all as read: $e');
      rethrow;
    }
  }

  /// Increment unread count
  Future<void> _incrementUnreadCount() async {
    try {
      final snapshot = await _database
          .ref('$_notificationsPath/unread_count')
          .get();
      final currentCount = (snapshot.value as int?) ?? 0;
      await _database
          .ref('$_notificationsPath/unread_count')
          .set(currentCount + 1);
    } catch (e) {
      print('[NOTIFICATIONS_SERVICE] Error incrementing unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('[NOTIFICATIONS_SERVICE] Marking $notificationId as read');

      final DataSnapshot event = await _database
          .ref('$_itemsPath/notif_$notificationId/is_read')
          .get();
      final bool wasRead = event.value as bool? ?? false;
      if (wasRead) {
        return;
      }

      await _database.ref('$_itemsPath/notif_$notificationId').update(
        <String, dynamic>{'is_read': true},
      );

      final snapshot = await _database
          .ref('$_notificationsPath/unread_count')
          .get();
      final currentCount = (snapshot.value as int?) ?? 0;
      if (currentCount > 0) {
        await _database
            .ref('$_notificationsPath/unread_count')
            .set(currentCount - 1);
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
          .ref('$_itemsPath/notif_$notificationId/is_read')
          .get();
      final wasRead = snapshot.value as bool? ?? true;

      await _database.ref('$_itemsPath/notif_$notificationId').remove();

      // Decrement unread count if it was unread
      if (!wasRead) {
        final countSnapshot = await _database
            .ref('$_notificationsPath/unread_count')
            .get();
        final currentCount = (countSnapshot.value as int?) ?? 0;
        if (currentCount > 0) {
          await _database
              .ref('$_notificationsPath/unread_count')
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
    return _database.ref(_itemsPath).onValue.map((event) {
      if (!event.snapshot.exists) {
        return <FarmNotification>[];
      }

      final Map<dynamic, dynamic> raw =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<FarmNotification> notifications = raw.entries.map((e) {
        final id = e.key.toString().replaceFirst('notif_', '');
        final map = Map<String, dynamic>.from(e.value);
        return FarmNotification.fromMap(id, map);
      }).toList();

      // Sort by created_at descending (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  /// Get real-time stream of unread count
  Stream<int> getUnreadCountStream() {
    return _database
        .ref('$_notificationsPath/unread_count')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }
}

