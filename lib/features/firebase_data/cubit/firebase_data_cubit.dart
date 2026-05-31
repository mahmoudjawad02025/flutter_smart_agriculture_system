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
      final DatabaseReference ref = FarmPayload.rootRef(_database);
      final Map<String, dynamic> data = await FarmPayload.sampleData();
      await ref.set(data);

      emit(
        state.copyWith(
          status: FirebaseDataStatus.success,
          message: 'تم كتابة البيانات بنجاح.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseDataStatus.error,
          message: 'فشل الكتابة: $error',
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
            message: 'لا توجد بيانات متاحة.',
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
          message: 'اكتملت عملية القراءة بنجاح.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseDataStatus.error,
          message: 'فشل القراءة: $error',
        ),
      );
    }
  }
}
