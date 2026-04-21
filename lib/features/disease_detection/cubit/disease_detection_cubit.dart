import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/disease_detection_service.dart';
import 'disease_detection_state.dart';

class DiseaseDetectionCubit extends Cubit<DiseaseDetectionState> {
  DiseaseDetectionCubit({
    required DiseaseDetectionService diseaseDetectionService,
  }) : _diseaseDetectionService = diseaseDetectionService,
       super(const DiseaseDetectionState());

  final DiseaseDetectionService _diseaseDetectionService;

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
            errorMessage: 'Image selection was cancelled.',
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
    } catch (error) {
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
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
          status: DiseaseDetectionStatus.error,
          errorMessage: 'Upload an image before connecting to the API.',
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

      // Attempt Firebase update, but don't fail if it errors
      String? firebaseError;
      try {
        print('[ANALYZE_IMAGE] Updating Firebase leaf status...');
        await _diseaseDetectionService.updateLeafStatusInFirebase(result);
        print('[ANALYZE_IMAGE] Firebase update completed!');
      } catch (firebaseErr) {
        // Store error message but continue - analysis was successful
        print('[ANALYZE_IMAGE] Firebase update FAILED: $firebaseErr');
        firebaseError = 'Firebase sync failed (non-critical): $firebaseErr';
      }

      // Emit success with analysis result, regardless of Firebase status
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.success,
          result: result,
          clearError: true,
          // Include Firebase error in state if occurred, but don't block UI
          errorMessage: firebaseError,
        ),
      );
      print('[ANALYZE_IMAGE] Analysis completed successfully!');
    } catch (error) {
      print('[ANALYZE_IMAGE] API ANALYSIS FAILED: $error');
      // This is the critical error: API call failed
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
          errorMessage:
              'API Analysis failed: $error\n\nTips:\n'
              '• Check image quality\n'
              '• Ensure good lighting\n'
              '• Verify Roboflow API key',
        ),
      );
    }
  }
}
