import 'package:equatable/equatable.dart';

enum FirebaseDataStatus { idle, loading, success, error }

class FirebaseDataState extends Equatable {
  const FirebaseDataState({
    this.status = FirebaseDataStatus.idle,
    this.message,
    this.nitrogen,
  });

  final FirebaseDataStatus status;
  final String? message;
  final int? nitrogen;

  FirebaseDataState copyWith({
    FirebaseDataStatus? status,
    String? message,
    bool clearMessage = false,
    int? nitrogen,
    bool clearNitrogen = false,
  }) {
    return FirebaseDataState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      nitrogen: clearNitrogen ? null : (nitrogen ?? this.nitrogen),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, message, nitrogen];
}
