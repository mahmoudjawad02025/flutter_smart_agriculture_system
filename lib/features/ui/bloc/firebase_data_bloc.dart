import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smart_cucumber_agriculture_system/features/logic/usecases/push_test_notification.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/read_nitrogen.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/usecases/write_sample_data.dart';
import 'firebase_data_state.dart';

class FirebaseDataCubit extends Cubit<FirebaseDataState> {
  FirebaseDataCubit({
    required WriteSampleData writeSampleData,
    required ReadNitrogen readNitrogen,
    required PushTestNotification pushTestNotification,
  }) : _writeSampleData = writeSampleData,
       _readNitrogen = readNitrogen,
       _pushTestNotification = pushTestNotification,
       super(const FirebaseDataState());

  final WriteSampleData _writeSampleData;
  final ReadNitrogen _readNitrogen;
  final PushTestNotification _pushTestNotification;

  Future<void> writeSampleData() async {
    emit(
      state.copyWith(status: FirebaseDataStatus.loading, clearMessage: true),
    );

    try {
      await _writeSampleData.call();

      emit(
        state.copyWith(
          status: FirebaseDataStatus.success,
          message: 'Data written successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseDataStatus.error,
          message: 'Write failed: $error',
        ),
      );
    }
  }

  Future<void> readNitrogenOnce() async {
    emit(
      state.copyWith(status: FirebaseDataStatus.loading, clearMessage: true),
    );

    try {
      final int? nitrogen = await _readNitrogen.call();

      if (nitrogen == null) {
        emit(
          state.copyWith(
            status: FirebaseDataStatus.error,
            message: 'No data available.',
            clearNitrogen: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: FirebaseDataStatus.success,
          nitrogen: nitrogen,
          message: 'Read completed successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseDataStatus.error,
          message: 'Read failed: $error',
        ),
      );
    }
  }

  Future<void> pushTestNotification() async {
    emit(
      state.copyWith(status: FirebaseDataStatus.loading, clearMessage: true),
    );
    try {
      await _pushTestNotification.call();

      emit(
        state.copyWith(
          status: FirebaseDataStatus.success,
          message: 'Test notification pushed!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseDataStatus.error,
          message: 'Push failed: $e',
        ),
      );
    }
  }
}
