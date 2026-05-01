import 'package:smart_cucumber_agriculture_system/features/data/models/farm_notification_model.dart';

abstract class NotificationsRepository {
  Stream<List<FarmNotification>> notificationsStream();
  Stream<int> unreadCountStream();
  Future<void> markAsRead(String id);
  Future<void> markAsUnread(String id);
  Future<void> markAllAsRead();
  Future<void> addDiseaseNotification({
    required String diseaseName,
    required String nextUpload,
    DateTime? createdAt,
  });
  Future<void> deleteNotification(String id);
}
