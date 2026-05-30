// ignore_for_file: avoid_print

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../notifications/cubit/notifications_cubit.dart';
import '../services/disease_detection_service.dart';
import 'disease_detection_state.dart';

class DiseaseDetectionCubit extends Cubit<DiseaseDetectionState> {
  DiseaseDetectionCubit({
    required DiseaseDetectionService diseaseDetectionService,
    required NotificationsCubit notificationsCubit,
  }) : _diseaseDetectionService = diseaseDetectionService,
       _notificationsCubit = notificationsCubit,
       super(const DiseaseDetectionState());

  final DiseaseDetectionService _diseaseDetectionService;
  final NotificationsCubit _notificationsCubit;

  Future<void> pickImageAndSave() async {
    emit(state.copyWith(status: DiseaseDetectionStatus.idle, clearError: true));

    try {
      final String? savedImagePath = await _diseaseDetectionService
          .pickAndSaveLeafImage();
      if (savedImagePath == null) {
        emit(
          state.copyWith(
            status: state.hasImage
                ? DiseaseDetectionStatus.imageReady
                : DiseaseDetectionStatus.idle,
            errorMessage: 'تم إلغاء اختيار الصورة.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.imageReady,
          imagePath: savedImagePath,
          previewRevision: DateTime.now().microsecondsSinceEpoch,
          clearResult: true,
          clearError: true,
        ),
      );

      // Trigger automatic analysis if enabled in settings
      if (AppRuntimeConfig.autoAnalyze.value) {
        await analyzeImage();
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
          errorMessage: 'فشل حفظ الصورة: $error',
        ),
      );
    }
  }

  Future<void> analyzeImage() async {
    final String? imagePath = state.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
          errorMessage: 'يرجى رفع صورة قبل الاتصال بخدمة التحليل.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: DiseaseDetectionStatus.analyzing,
        clearError: true,
      ),
    );

    print('[ANALYZE_IMAGE] Starting image analysis...');

    try {
      print('[ANALYZE_IMAGE] Calling Roboflow API...');
      final result = await _diseaseDetectionService.analyzeSavedImage(
        imagePath,
      );
      print(
        '[ANALYZE_IMAGE] API returned successfully: ${result.detectedLabels}',
      );

      String? firebaseError;
      try {
        print('[ANALYZE_IMAGE] Updating Firebase leaf status...');
        await _diseaseDetectionService.updateLeafStatusInFirebase(result);
        print('[ANALYZE_IMAGE] Firebase update completed!');
      } catch (firebaseErr) {
        print('[ANALYZE_IMAGE] Firebase update FAILED: $firebaseErr');
        firebaseError = 'مزامنة Firebase فشلت (غير حرجة): $firebaseErr';
      }

      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.success,
          result: result,
          clearError: true,
          errorMessage: firebaseError,
        ),
      );

      final bool isHealthy = _isHealthy(result.detectedLabels);
      if (!isHealthy && result.detectedLabels.isNotEmpty) {
        // Only send notification if user enabled push notifications in settings
        if (AppRuntimeConfig.pushNotifications.value) {
          final String diseaseName = result.detectedLabels.first;
          final String nextUpload = DateTime.now()
              .toUtc()
              .add(
                Duration(days: AppRuntimeConfig.diseaseReuploadDelayDays.value),
              )
              .toIso8601String();

          await _notificationsCubit.addDiseaseNotification(
            diseaseName: diseaseName,
            nextUpload: nextUpload,
            createdAt: DateTime.now(),
          );

          print('[ANALYZE_IMAGE] Notification added for disease: $diseaseName');
        } else {
          print(
            '[ANALYZE_IMAGE] Push notifications are disabled. Skipping notification.',
          );
        }
      }

      print('[ANALYZE_IMAGE] Analysis completed successfully!');
    } catch (error) {
      print('[ANALYZE_IMAGE] API ANALYSIS FAILED: $error');
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
          errorMessage:
              'فشل تحليل API: $error\n\n'
              'نصائح:\n'
              '• تحقق من جودة الصورة\n'
              '• تأكد من وجود إضاءة جيدة\n'
              '• تحقق من مفتاح Roboflow API',
        ),
      );
    }
  }

  bool _isHealthy(List<String> labels) {
    if (labels.isEmpty) {
      return false;
    }

    final List<String> keywords = AppRuntimeConfig.healthyKeywords.value
        .map((String value) => value.toLowerCase())
        .toList();

    return labels.every((String label) {
      final String normalized = label.toLowerCase();
      return keywords.any(normalized.contains);
    });
  }
}
