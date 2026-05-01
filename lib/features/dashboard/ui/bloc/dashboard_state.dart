import 'package:equatable/equatable.dart';

enum DashboardStatus { idle, loading, success, error }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.idle,
    this.message,
    this.nitrogen,
  });

  final DashboardStatus status;
  final String? message;
  final int? nitrogen;

  DashboardState copyWith({
    DashboardStatus? status,
    String? message,
    bool clearMessage = false,
    int? nitrogen,
    bool clearNitrogen = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      nitrogen: clearNitrogen ? null : (nitrogen ?? this.nitrogen),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, message, nitrogen];
}
