import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/room_repository.dart';
import 'rooms_event.dart';
import 'rooms_state.dart';

class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  final RoomRepository roomRepo;

  RoomsBloc({required this.roomRepo}) : super(const RoomsState()) {
    on<RoomsStarted>(_onStarted);
    on<RoomsRefreshRequested>(_onRefresh);

    on<RoomCreateRequested>(_onCreate);
    on<RoomRenameRequested>(_onRename);
    on<RoomDeleteRequested>(_onDelete);
  }

  Future<void> _onStarted(RoomsStarted event, Emitter<RoomsState> emit) async {
    emit(state.copyWith(status: RoomsStatus.loading, clearError: true));
    try {
      final rooms = await roomRepo.fetchRooms();
      emit(state.copyWith(status: RoomsStatus.ready, rooms: rooms, clearError: true));
    } catch (e, st) {
      debugPrint('[RoomsBloc] started failed: $e\n$st');
      emit(state.copyWith(status: RoomsStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRefresh(RoomsRefreshRequested event, Emitter<RoomsState> emit) async {
    // keep UI stable; you can choose loading if you want
    try {
      final rooms = await roomRepo.fetchRooms();
      emit(state.copyWith(status: RoomsStatus.ready, rooms: rooms, clearError: true));
    } catch (e) {
      emit(state.copyWith(status: RoomsStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onCreate(RoomCreateRequested event, Emitter<RoomsState> emit) async {
    final name = event.roomName.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(status: RoomsStatus.saving, clearError: true));
    try {
      await roomRepo.createRoom(roomName: name);
      final rooms = await roomRepo.fetchRooms();
      emit(state.copyWith(status: RoomsStatus.ready, rooms: rooms, clearError: true));
    } catch (e, st) {
      debugPrint('[RoomsBloc] create failed: $e\n$st');
      emit(state.copyWith(status: RoomsStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRename(RoomRenameRequested event, Emitter<RoomsState> emit) async {
    final name = event.roomName.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(status: RoomsStatus.saving, clearError: true));
    try {
      await roomRepo.updateRoom(roomId: event.roomId, roomName: name);
      final rooms = await roomRepo.fetchRooms();
      emit(state.copyWith(
      status: RoomsStatus.success, // ← THIS is when your listener triggers
      rooms: rooms,
    ));
      emit(state.copyWith(status: RoomsStatus.ready, rooms: rooms, clearError: true));
    } catch (e, st) {
      debugPrint('[RoomsBloc] rename failed: $e\n$st');
      emit(state.copyWith(status: RoomsStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDelete(RoomDeleteRequested event, Emitter<RoomsState> emit) async {
    emit(state.copyWith(status: RoomsStatus.deleting, clearError: true));
    try {
      await roomRepo.deleteRoom(roomId: event.roomId);
      final rooms = await roomRepo.fetchRooms();
      emit(state.copyWith(status: RoomsStatus.ready, rooms: rooms, clearError: true));
    } catch (e, st) {
      debugPrint('[RoomsBloc] delete failed: $e\n$st');
      emit(state.copyWith(status: RoomsStatus.failure, error: e.toString()));
    }
  }
}