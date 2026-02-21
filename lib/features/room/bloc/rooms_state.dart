import 'package:equatable/equatable.dart';
import '../../home/models/room.dart';

enum RoomsStatus { initial, loading, ready, saving, deleting, failure, success }

class RoomsState extends Equatable {
  final RoomsStatus status;
  final List<Room> rooms;
  final String? error;

  const RoomsState({
    this.status = RoomsStatus.initial,
    this.rooms = const [],
    this.error,
  });

  RoomsState copyWith({
    RoomsStatus? status,
    List<Room>? rooms,
    String? error,
    bool clearError = false,
  }) {
    return RoomsState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, rooms, error];
}