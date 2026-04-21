import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/farm_payload.dart';
import 'firebase_data_state.dart';

class FirebaseDataCubit extends Cubit<FirebaseDataState> {
  FirebaseDataCubit({required FirebaseDatabase database})
    : _database = database,
      super(const FirebaseDataState());

  final FirebaseDatabase _database;

  Future<void> writeSampleData() async {
    emit(
      state.copyWith(status: FirebaseDataStatus.loading, clearMessage: true),
    );

    try {
      final DatabaseReference ref = _database.ref(FarmPayload.rootPath);

      await ref.set(FarmPayload.sampleData());

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
      final DataSnapshot snapshot = await _database
          .ref(FarmPayload.nitrogenPath)
          .get();

      if (!snapshot.exists) {
        emit(
          state.copyWith(
            status: FirebaseDataStatus.error,
            message: 'No data available.',
            clearNitrogen: true,
          ),
        );
        return;
      }

      final dynamic rawValue = snapshot.value;
      final int? nitrogen = rawValue is int
          ? rawValue
          : int.tryParse('$rawValue');

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
}
