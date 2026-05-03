// ignore_for_file: avoid_print

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_agriculture_system/features/notifications/data/models/farm_notification_model.dart';
import 'package:flutter_smart_agriculture_system/features/notifications/domain/repositories/notifications_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationsRepository notificationsService})
    : _notificationsService = notificationsService,
      super(
        const NotificationsState(
          notifications: <FarmNotification>[],
          unreadCount: 0,
        ),
      ) {
    _bindFirebaseStreams();
  }

  final NotificationsRepository _notificationsService;
  StreamSubscription<List<FarmNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  void _bindFirebaseStreams() {
    _notificationsSubscription = _notificationsService
        .notificationsStream()
        .listen((List<FarmNotification> notifications) {
          emit(state.copyWith(notifications: notifications));
        });

    _unreadCountSubscription = _notificationsService.unreadCountStream().listen(
      (int unreadCount) {
        emit(state.copyWith(unreadCount: unreadCount));
      },
    );
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
    await _unreadCountSubscription?.cancel();
    return super.close();
  }
}
