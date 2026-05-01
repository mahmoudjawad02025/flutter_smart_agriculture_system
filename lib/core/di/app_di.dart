import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_cucumber_agriculture_system/core/config/roboflow_config.dart';
import 'package:smart_cucumber_agriculture_system/core/network/dio_client.dart';
import 'package:smart_cucumber_agriculture_system/features/data/datasources/auth_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/data/datasources/disease_detection_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/data/datasources/notifications_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/data/repositories/auth_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/data/repositories/disease_detection_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/data/repositories/firebase_data_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/data/repositories/notifications_repo_impl.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/write_sample_data.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/read_nitrogen.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/push_test_notification.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/get_farm_data_once.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/watch_farm_data.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/watch_logs.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/update_crop_targets.dart';

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

  static DiseaseDetectionRepositoryImpl provideDiseaseRepository() {
    final DiseaseDetectionService ds = DiseaseDetectionService(
      imagePicker: ImagePicker(),
      dio: DioClient.create(),
      database: FirebaseDatabase.instance,
      config: const RoboflowConfig(),
    );
    return DiseaseDetectionRepositoryImpl(ds);
  }

  static FirebaseDataRepositoryImpl provideFirebaseDataRepository() {
    return FirebaseDataRepositoryImpl(database: FirebaseDatabase.instance);
  }

  // Usecases
  static WriteSampleData provideWriteSampleDataUsecase() {
    return WriteSampleData(provideFirebaseDataRepository());
  }

  static ReadNitrogen provideReadNitrogenUsecase() {
    return ReadNitrogen(provideFirebaseDataRepository());
  }

  static PushTestNotification providePushTestNotificationUsecase() {
    return PushTestNotification(provideFirebaseDataRepository());
  }

  static GetFarmDataOnce provideGetFarmDataOnceUsecase() {
    return GetFarmDataOnce(provideFirebaseDataRepository());
  }

  static WatchFarmData provideWatchFarmDataUsecase() {
    return WatchFarmData(provideFirebaseDataRepository());
  }

  static WatchLogs provideWatchLogsUsecase() {
    return WatchLogs(provideFirebaseDataRepository());
  }

  static UpdateCropTargets provideUpdateCropTargetsUsecase() {
    return UpdateCropTargets(provideFirebaseDataRepository());
  }
}
