import '../models/device_widget.dart';
import '../models/room.dart';

class DevicesState {
  final bool isLoading;

  /// rooms from backend
  final List<Room> rooms;

  /// null means "All"
  final int? selectedRoomId;

  final bool selectedRoomIdSet;

  /// widgets from backend
  final List<DeviceWidget> widgets;

  final String? error;

  const DevicesState({
    this.isLoading = false,
    this.rooms = const [],
    this.selectedRoomId,
    this.selectedRoomIdSet = false,
    this.widgets = const [],
    this.error,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    int? selectedRoomId,            // can be null
    bool selectedRoomIdSet = false, // tells copyWith “I want to update it”
    List<DeviceWidget>? widgets,
    Map<int, int>? deviceRoomId,
    String? error,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      selectedRoomId: selectedRoomIdSet ? selectedRoomId : this.selectedRoomId,
      selectedRoomIdSet: selectedRoomIdSet ? true : this.selectedRoomIdSet,
      widgets: widgets ?? this.widgets,
      error: error,
    );
  }

  /// One card per widget
  List<DeviceWidget> get visibleWidgets {
    // If widgets are already fetched by room, DO NOT filter by deviceRoomId.
    // Just filter by status (if you want to hide inactive).
    final base = widgets.where((w) => w.status != 'inactive').toList();

    base.sort((a, b) {
      final did = a.device.id.compareTo(b.device.id);
      if (did != 0) return did;
      return a.order.compareTo(b.order);
    });

    return base;
  }

  Room? get selectedRoom {
    final rid = selectedRoomId;
    if (rid == null) return null;
    for (final r in rooms) {
      if (r.id == rid) return r;
    }
    return null;
  }
}
