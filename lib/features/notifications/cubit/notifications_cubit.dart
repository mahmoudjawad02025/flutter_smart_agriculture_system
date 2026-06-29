// ignore_for_file: avoid_print

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/farm_notification.dart';
import '../services/notifications_service.dart';
import '../services/reupload_reminder_service.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationsService notificationsService,
    required FirebaseDatabase database,
  }) : _notificationsService = notificationsService,
       _reuploadReminderService = ReuploadReminderService(
         database: database,
         notificationsService: notificationsService,
       ),
       super(
         const NotificationsState(
           notifications: <FarmNotification>[],
           unreadCount: 0,
         ),
       ) {
    _bindFirebaseStreams();
    _reuploadReminderService.start();
  }

  final NotificationsService _notificationsService;
  final ReuploadReminderService _reuploadReminderService;
  StreamSubscription<List<FarmNotification>>? _notificationsSubscription;

  void _bindFirebaseStreams() {
    _notificationsSubscription = _notificationsService
        .getNotificationsStream()
        .listen((List<FarmNotification> notifications) {
          final int unreadCount = notifications
              .where((FarmNotification n) => !n.isRead)
              .length;
          emit(
            state.copyWith(
              notifications: notifications,
              unreadCount: unreadCount,
            ),
          );
        });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsService.markAsRead(notificationId);
    } catch (e) {
      print('[NOTIFICATIONS] Error marking as read: $e');
    }
  }

  Future<void> markAsUnread(String notificationId) async {
    try {
      await _notificationsService.markAsUnread(notificationId);
    } catch (e) {
      print('[NOTIFICATIONS] Error marking as unread: $e');
    }
  }

  Future<void> addDiseaseNotification({
    required String diseaseName,
    required String nextUpload,
    DateTime? createdAt,
  }) async {
    try {
      await _notificationsService.addDiseaseNotification(
        diseaseName: diseaseName,
        nextUpload: nextUpload,
        createdAt: createdAt,
      );
    } catch (e) {
      print('[NOTIFICATIONS] Error adding notification: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsService.deleteNotification(notificationId);
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _notificationsService.deleteAllNotifications();
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting all notifications: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();
    } catch (e) {
      print('[NOTIFICATIONS] Error marking all as read: $e');
    }
  }

  @override
  Future<void> close() async {
    await _notificationsSubscription?.cancel();
    await _reuploadReminderService.dispose();
    return super.close();
  }
}
