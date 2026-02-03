import '../models/device.dart';
import '../models/device_widget.dart';
import '../models/room.dart';

class DevicesState {
  final bool isLoading;

  /// rooms from backend
  final List<Room> rooms;

  /// null means "All"
  final int? selectedRoomId;

  /// devices from backend
  final List<Device> devices;

  /// widgets from backend
  final List<DeviceWidget> widgets;

  /// deviceId(int) -> roomId(int)
  final Map<int, int> deviceRoomId;

  final String? error;

  const DevicesState({
    this.isLoading = false,
    this.rooms = const [],
    this.selectedRoomId,
    this.devices = const [],
    this.widgets = const [],
    this.deviceRoomId = const {},
    this.error,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    int? selectedRoomId,            // can be null
    bool selectedRoomIdSet = false, // tells copyWith “I want to update it”
    List<Device>? devices,
    List<DeviceWidget>? widgets,
    Map<int, int>? deviceRoomId,
    String? error,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      selectedRoomId: selectedRoomIdSet ? selectedRoomId : this.selectedRoomId,
      devices: devices ?? this.devices,
      widgets: widgets ?? this.widgets,
      deviceRoomId: deviceRoomId ?? this.deviceRoomId,
      error: error,
    );
  }

  List<Device> get visibleDevices {
    final rid = selectedRoomId;
    if (rid == null) return devices;

    return devices.where((d) => deviceRoomId[d.id] == rid).toList();
  }

  /// One card per widget
  List<DeviceWidget> get visibleWidgets {
    final rid = selectedRoomId;

    final base = widgets.where((w) => w.status == 'include');

    final filtered = rid == null
        ? base.toList()
        : base.where((w) => deviceRoomId[w.device.id] == rid).toList();

    // Stable sorting: by device id then order (helps when many widgets share same order)
    filtered.sort((a, b) {
      final did = a.device.id.compareTo(b.device.id);
      if (did != 0) return did;
      return a.order.compareTo(b.order);
    });

    return filtered;
  }

  int get deviceCount => visibleDevices.length;

  Room? get selectedRoom {
    final rid = selectedRoomId;
    if (rid == null) return null;
    for (final r in rooms) {
      if (r.id == rid) return r;
    }
    return null;
  }
}
