import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/data/models/farm_payload_model.dart';
import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/repositories/dashboard_repo.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required FirebaseDatabase database})
    : _db = database;

  final FirebaseDatabase _db;

  @override
  Future<void> writeSampleData() async {
    final DatabaseReference ref = _db.ref(FarmPayload.rootPath);
    await ref.set(FarmPayload.sampleData());
  }

  @override
  Future<int?> readNitrogenOnce() async {
    final DataSnapshot snapshot = await _db.ref(FarmPayload.nitrogenPath).get();
    if (!snapshot.exists) return null;
    final dynamic rawValue = snapshot.value;
    final int? nitrogen = rawValue is int
        ? rawValue
        : int.tryParse('$rawValue');
    return nitrogen;
  }

  @override
  Future<void> pushTestNotification() async {
    final String id = 'test_notif_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _db.ref('${FarmPayload.rootPath}/notifications/items/$id');

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

    final countRef = _db.ref(
      '${FarmPayload.rootPath}/notifications/unread_count',
    );
    final current = await countRef.get();
    final currentVal = (current.value as int? ?? 0);
    await countRef.set(currentVal + 1);
  }

  @override
  Future<Map<String, dynamic>?> getFarmDataOnce() async {
    final DataSnapshot snapshot = await _db.ref(FarmPayload.rootPath).get();
    if (!snapshot.exists) return null;
    final dynamic raw = snapshot.value;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Stream<Map<String, dynamic>?> watchFarmData() async* {
    await for (final DatabaseEvent event
        in _db.ref(FarmPayload.rootPath).onValue) {
      final dynamic raw = event.snapshot.value;
      if (raw is Map) {
        yield Map<String, dynamic>.from(raw);
      } else {
        yield null;
      }
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchLogs() async* {
    await for (final DatabaseEvent event
        in _db.ref('${FarmPayload.rootPath}/logs').onValue) {
      final dynamic raw = event.snapshot.value;
      if (raw is Map) {
        yield Map<String, dynamic>.from(raw);
      } else {
        yield null;
      }
    }
  }

  @override
  Future<void> updateCropTargets({
    required int moistMin,
    required int moistMax,
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
  }) async {
    final DatabaseReference goalsRef = _db.ref(
      '${FarmPayload.rootPath}/actions/goals',
    );
    await goalsRef.update(<String, dynamic>{
      'moist_min': moistMin,
      'moist_max': moistMax,
      'n_min': nMin,
      'n_max': nMax,
      'p_min': pMin,
      'p_max': pMax,
      'k_min': kMin,
      'k_max': kMax,
      'leaf_goal': leafGoal,
    });
  }
}

