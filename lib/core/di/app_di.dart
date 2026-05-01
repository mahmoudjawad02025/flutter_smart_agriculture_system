import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_cucumber_agriculture_system/core/config/roboflow_config.dart';
import 'package:smart_cucumber_agriculture_system/core/network/dio_client.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/data/datasources/auth_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/datasources/ai_detection_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/notifications/data/datasources/notifications_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/data/repositories/auth_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/repositories/ai_detection_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/data/repositories/dashboard_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/notifications/data/repositories/notifications_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/diagnostics/domain/usecases/write_sample_data.dart';
import 'package:smart_cucumber_agriculture_system/features/diagnostics/domain/usecases/read_nitrogen.dart';
import 'package:smart_cucumber_agriculture_system/features/diagnostics/domain/usecases/push_test_notification.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/usecases/get_farm_data_once.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/usecases/watch_farm_data.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/usecases/watch_logs.dart';
import 'package:smart_cucumber_agriculture_system/features/configurations/domain/usecases/update_crop_targets.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/domain/usecases/ai_detection_usecases.dart';

class AppDi {
  const AppDi._();

  static AuthRepositoryImpl provideAuthRepository() {
    final AuthService ds = AuthService(
      firebaseAuth: FirebaseAuth.instance,
      database: FirebaseDatabase.instance,
    );
    return AuthRepositoryImpl(ds);
  }

  static NotificationsRepositoryImpl provideNotificationsRepository() {
    final NotificationsService ds = NotificationsService(
      database: FirebaseDatabase.instance,
    );
    return NotificationsRepositoryImpl(ds);
  }

  static AiDetectionRepositoryImpl provideAiDetectionRepository() {
    final AiDetectionService ds = AiDetectionService(
      imagePicker: ImagePicker(),
      dio: DioClient.create(),
      database: FirebaseDatabase.instance,
      config: const RoboflowConfig(),
    );
    return AiDetectionRepositoryImpl(ds);
  }

  static DashboardRepositoryImpl provideDashboardRepository() {
    return DashboardRepositoryImpl(database: FirebaseDatabase.instance);
  }

  // Usecases
  static WriteSampleData provideWriteSampleDataUsecase() {
    return WriteSampleData(provideDashboardRepository());
  }

  static ReadNitrogen provideReadNitrogenUsecase() {
    return ReadNitrogen(provideDashboardRepository());
  }

  static PushTestNotification providePushTestNotificationUsecase() {
    return PushTestNotification(provideDashboardRepository());
  }

  static GetFarmDataOnce provideGetFarmDataOnceUsecase() {
    return GetFarmDataOnce(provideDashboardRepository());
  }

  static WatchFarmData provideWatchFarmDataUsecase() {
    return WatchFarmData(provideDashboardRepository());
  }

  static WatchLogs provideWatchLogsUsecase() {
    return WatchLogs(provideDashboardRepository());
  }

  static UpdateCropTargets provideUpdateCropTargetsUsecase() {
    return UpdateCropTargets(provideDashboardRepository());
  }

  static PickAndSaveLeafImage providePickAndSaveLeafImageUsecase() {
    return PickAndSaveLeafImage(provideAiDetectionRepository());
  }

  static AnalyzeLeafImage provideAnalyzeLeafImageUsecase() {
    return AnalyzeLeafImage(provideAiDetectionRepository());
  }

  static UpdateLeafStatus provideUpdateLeafStatusUsecase() {
    return UpdateLeafStatus(provideAiDetectionRepository());
  }
}

