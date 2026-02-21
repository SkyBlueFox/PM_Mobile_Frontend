import 'package:equatable/equatable.dart';

abstract class RoomsEvent extends Equatable {
  const RoomsEvent();
  @override
  List<Object?> get props => [];
}

class RoomsStarted extends RoomsEvent {
  const RoomsStarted();
}

class RoomsRefreshRequested extends RoomsEvent {
  const RoomsRefreshRequested();
}

class RoomCreateRequested extends RoomsEvent {
  final String roomName;
  const RoomCreateRequested(this.roomName);

  @override
  List<Object?> get props => [roomName];
}

class RoomRenameRequested extends RoomsEvent {
  final int roomId;
  final String roomName;
  const RoomRenameRequested({required this.roomId, required this.roomName});

  @override
  List<Object?> get props => [roomId, roomName];
}

class RoomDeleteRequested extends RoomsEvent {
  final int roomId;
  const RoomDeleteRequested(this.roomId);

  @override
  List<Object?> get props => [roomId];
}