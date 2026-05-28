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

  Future<void> pushTestNotification() async {
    emit(
      state.copyWith(status: FirebaseDataStatus.loading, clearMessage: true),
    );
    try {
      final String id = 'test_notif_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _database.ref('${FarmPayload.notificationItemsPath}/$id');

      await ref.set({
        'title': 'System Test Alert',
        'message': 'This is a manual test notification to verify cloud sync.',
        'disease_name': 'Manual_Test',
        'next_upload': DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String(),
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update unread count
      final countRef = _database.ref(FarmPayload.unreadCountPath);
      final current = await countRef.get();
      final currentVal = (current.value as int? ?? 0);
      await countRef.set(currentVal + 1);

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
