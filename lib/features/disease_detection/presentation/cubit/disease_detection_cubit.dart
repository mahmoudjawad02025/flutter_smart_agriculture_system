import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/analyze_leaf_image_usecase.dart';
import '../../domain/usecases/pick_and_store_image_usecase.dart';
import 'disease_detection_state.dart';

class DiseaseDetectionCubit extends Cubit<DiseaseDetectionState> {
  DiseaseDetectionCubit({
    required PickAndStoreImageUseCase pickAndStoreImageUseCase,
    required AnalyzeLeafImageUseCase analyzeLeafImageUseCase,
  }) : _pickAndStoreImageUseCase = pickAndStoreImageUseCase,
       _analyzeLeafImageUseCase = analyzeLeafImageUseCase,
       super(const DiseaseDetectionState());

  final PickAndStoreImageUseCase _pickAndStoreImageUseCase;
  final AnalyzeLeafImageUseCase _analyzeLeafImageUseCase;

  Future<void> pickImageAndSave() async {
    emit(state.copyWith(status: DiseaseDetectionStatus.idle, clearError: true));

    try {
      final String? savedImagePath = await _pickAndStoreImageUseCase();
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

    try {
      final result = await _analyzeLeafImageUseCase(imagePath);
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.success,
          result: result,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DiseaseDetectionStatus.error,
          errorMessage: 'API request failed: $error',
        ),
      );
    }
  }
}
