// ignore_for_file: avoid_print

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_agriculture_system/core/config/app_runtime_config.dart';
import 'package:flutter_smart_agriculture_system/features/notifications/ui/bloc/notifications_bloc.dart';

import 'ai_detection_state.dart';
import 'package:flutter_smart_agriculture_system/features/ai_detection/domain/usecases/ai_detection_usecases.dart';

class AiDetectionCubit extends Cubit<AiDetectionState> {
  AiDetectionCubit({
    required PickAndSaveLeafImage pickAndSaveLeafImage,
    required AnalyzeLeafImage analyzeLeafImage,
    required UpdateLeafStatus updateLeafStatus,
    required NotificationsCubit notificationsCubit,
  }) : _pickAndSaveLeafImage = pickAndSaveLeafImage,
       _analyzeLeafImage = analyzeLeafImage,
       _updateLeafStatus = updateLeafStatus,
       _notificationsCubit = notificationsCubit,
       super(const AiDetectionState());

  final PickAndSaveLeafImage _pickAndSaveLeafImage;
  final AnalyzeLeafImage _analyzeLeafImage;
  final UpdateLeafStatus _updateLeafStatus;
  final NotificationsCubit _notificationsCubit;

  Future<void> pickImageAndSave() async {
    emit(state.copyWith(status: AiDetectionStatus.idle, clearError: true));

    try {
      final String? savedImagePath = await _pickAndSaveLeafImage.call();
      if (savedImagePath == null) {
        emit(
          state.copyWith(
            status: state.hasImage
                ? AiDetectionStatus.imageReady
                : AiDetectionStatus.idle,
            errorMessage: 'Image selection was cancelled.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AiDetectionStatus.imageReady,
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
          status: AiDetectionStatus.error,
          errorMessage: 'Failed to save image: $error',
        ),
      );
    }
  }

  Future<void> analyzeImage() async {
    final String? imagePath = state.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      emit(
        state.copyWith(
          status: AiDetectionStatus.error,
          errorMessage: 'Upload an image before connecting to the API.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AiDetectionStatus.analyzing, clearError: true));

    print('[ANALYZE_IMAGE] Starting image analysis...');

    try {
      print('[ANALYZE_IMAGE] Calling Roboflow API...');
      final result = await _analyzeLeafImage.call(imagePath);
      print(
        '[ANALYZE_IMAGE] API returned successfully: ${result.detectedLabels}',
      );

      String? firebaseError;
      try {
        print('[ANALYZE_IMAGE] Updating Firebase leaf status...');
        await _updateLeafStatus.call(result);
        print('[ANALYZE_IMAGE] Firebase update completed!');
      } catch (firebaseErr) {
        print('[ANALYZE_IMAGE] Firebase update FAILED: $firebaseErr');
        firebaseError = 'Firebase sync failed (non-critical): $firebaseErr';
      }

      emit(
        state.copyWith(
          status: AiDetectionStatus.success,
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
          status: AiDetectionStatus.error,
          errorMessage:
              'API Analysis failed: $error\n\nTips:\n'
              '• Check image quality\n'
              '• Ensure good lighting\n'
              '• Verify Roboflow API key',
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
      return keywords.any(normalized.contains) ||
          normalized == 'bacterialspot' ||
          normalized == 'tomato_bacterial_spot';
    });
  }
}
