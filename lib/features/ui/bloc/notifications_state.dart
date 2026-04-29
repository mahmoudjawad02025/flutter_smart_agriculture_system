part of 'notifications_bloc.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    required this.notifications,
    required this.unreadCount,
  });

  final List<FarmNotification> notifications;
  final int unreadCount;

  NotificationsState copyWith({
    List<FarmNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[notifications, unreadCount];
}
