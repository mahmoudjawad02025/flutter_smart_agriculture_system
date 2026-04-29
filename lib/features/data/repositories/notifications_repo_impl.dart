import 'package:smart_cucumber_agriculture_system/data/datasources/notifications_ds.dart';
import 'package:smart_cucumber_agriculture_system/data/models/farm_notification_model.dart';
import 'package:smart_cucumber_agriculture_system/logic/repositories/notifications_repo.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._dataSource);

  final NotificationsService _dataSource;

  @override
  Stream<List<FarmNotification>> notificationsStream() {
    return _dataSource.getNotificationsStream();
  }

  @override
  Stream<int> unreadCountStream() => _dataSource.getUnreadCountStream();

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();

  @override
  Future<void> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<void> markAsUnread(String id) => _dataSource.markAsUnread(id);

  @override
  Future<void> addDiseaseNotification({
    required String diseaseName,
    required String nextUpload,
    DateTime? createdAt,
  }) => _dataSource.addDiseaseNotification(
    diseaseName: diseaseName,
    nextUpload: nextUpload,
    createdAt: createdAt,
  );

  @override
  Future<void> deleteNotification(String id) =>
      _dataSource.deleteNotification(id);
}
