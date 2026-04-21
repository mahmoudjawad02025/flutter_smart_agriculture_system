import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notifications_cubit.dart';
import '../models/farm_notification.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              return TextButton.icon(
                onPressed: state.unreadCount == 0
                    ? null
                    : () {
                        context.read<NotificationsCubit>().markAllAsRead();
                      },
                icon: const Icon(Icons.done_all_outlined, color: Colors.white),
                label: Text(
                  'Mark all',
                  style: TextStyle(
                    color: state.unreadCount == 0
                        ? Colors.white54
                        : Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              _SummaryCard(unreadCount: state.unreadCount),
              const SizedBox(height: 12),
              ...state.notifications.map(
                (FarmNotification notification) =>
                    _NotificationCard(notification: notification),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final FarmNotification notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: notification.isRead
                  ? Colors.grey[400]!
                  : const Color(0xFF2E7D32),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.warning_outlined,
                      color: Color(0xFFD32F2F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: notification.isRead
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        if (!notification.isRead) const SizedBox(height: 4),
                        if (!notification.isRead)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: const Text(
                              'Unread',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Disease: ${notification.diseaseName.replaceAll('_', ' ')}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Appeared: ${_formatTimestamp(notification.createdAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.schedule_outlined, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Next upload: ${_formatDate(notification.nextUpload)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton.icon(
                    icon: Icon(
                      notification.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.done_outline,
                      size: 16,
                    ),
                    label: Text(
                      notification.isRead ? 'Mark Unread' : 'Mark Read',
                    ),
                    onPressed: () {
                      final cubit = context.read<NotificationsCubit>();
                      if (notification.isRead) {
                        cubit.markAsUnread(notification.id);
                      } else {
                        cubit.markAsRead(notification.id);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    icon: const Icon(Icons.close_outlined, size: 16),
                    label: const Text('Delete'),
                    onPressed: () {
                      context.read<NotificationsCubit>().deleteNotification(
                        notification.id,
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays > 0) {
        return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
      } else {
        return 'Soon';
      }
    } catch (e) {
      return isoString.split('T')[0];
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateTime local = timestamp.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
              },
            ),
            if (state.unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF66A652)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          const Icon(Icons.notifications_active_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unreadCount == 0
                  ? 'No unread notifications'
                  : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
