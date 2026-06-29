import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../cubit/notifications_cubit.dart';
import '../models/farm_notification.dart';
import '../models/notification_display.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: <Widget>[
          // Mark all as read
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: state.unreadCount == 0
                      ? null
                      : () {
                          context.read<NotificationsCubit>().markAllAsRead();
                        },
                  icon: const Icon(Icons.done_all_outlined, size: 18),
                  label: const Text('وضع الكل كمقروء'),
                ),
              );
            },
          ),

          // Delete all notifications
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text(
                      'هل تريد حذف جميع الإشعارات؟ هذا الإجراء لا يمكن التراجع عنه.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // ignore: use_build_context_synchronously
                  context.read<NotificationsCubit>().deleteAllNotifications();
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('حذف الكل'),
            ),
          ),

          const SizedBox(width: 4),
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
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات حتى الآن',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سننبهك هنا إذا وجدنا مشاكل.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return PaginatedListView(
            padding: const EdgeInsets.all(14),
            itemCount: state.notifications.length,
            header: _SummaryCard(unreadCount: state.unreadCount),
            itemBuilder: (BuildContext context, int index) {
              final FarmNotification notification = state.notifications[index];
              return _NotificationCard(notification: notification);
            },
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
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ValueListenableBuilder<bool>(
        valueListenable: AppRuntimeConfig.strongAlertMode,
        builder: (context, isStrongAlert, _) {
          final NotificationDisplay display = NotificationDisplay.resolve(
            notification,
            isStrongAlertMode: isStrongAlert,
          );

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: display.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        display.icon,
                        color: display.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  display.titleText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: notification.isRead
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimeOnly(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: display.accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'جديد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(
                      display.icon,
                      size: 14,
                      color: display.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      display.isDisease && display.detailLabel != null
                          ? 'كشف: ${display.detailLabel}'
                          : 'النوع: ${display.categoryLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: display.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  display.bodyText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (notification.nextUpload.isNotEmpty && display.isDisease)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.schedule_outlined,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إعادة رفع لاحقة: ${_formatTimestamp(DateTime.tryParse(notification.nextUpload) ?? DateTime.now())}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: <Widget>[
                        _ActionButton(
                          icon: notification.isRead
                              ? Icons.mark_email_unread_outlined
                              : Icons.mark_email_read_outlined,
                          onPressed: () {
                            if (notification.isRead) {
                              context.read<NotificationsCubit>().markAsUnread(
                                notification.id,
                              );
                            } else {
                              context.read<NotificationsCubit>().markAsRead(
                                notification.id,
                              );
                            }
                          },
                          color: notification.isRead
                              ? Colors.blue
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          onPressed: () {
                            context
                                .read<NotificationsCubit>()
                                .deleteNotification(notification.id);
                          },
                          color: Colors.red[700]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
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
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'تحديث سريع',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount == 0
                      ? 'لا توجد تنبيهات جديدة. تتم مراقبة محاصيلك.'
                      : 'لديك $unreadCount تنبيهات غير مقروءة تحتاج إلى انتباهك.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return Badge.count(
          count: state.unreadCount,
          isLabelVisible: state.unreadCount > 0,
          offset: const Offset(-2, 2),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'عرض الإشعارات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
