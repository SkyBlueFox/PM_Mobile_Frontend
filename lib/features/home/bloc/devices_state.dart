// lib/features/home/bloc/devices_state.dart
//
// State for DevicesBloc.
// หลักการ: state เป็น immutable, copyWith ชัดเจน (KISS)
// เอา class ซ้ำออก (ของเดิมคุณมีซ้ำ 2 ชุด)

import '../models/device_widget.dart';
import '../models/room.dart';

class DevicesState {
  final bool isLoading;

  /// rooms from backend
  final List<Room> rooms;

  /// null means "All"
  final int? selectedRoomId;

  /// widgets from backend (รวม active + inactive)
  final List<DeviceWidget> widgets;

  /// user-facing error (สั้นพอ)
  final String? error;

  const DevicesState({
    this.isLoading = false,
    this.rooms = const [],
    this.selectedRoomId,
    this.widgets = const [],
    this.error,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    int? selectedRoomId, // allow null
    List<DeviceWidget>? widgets,
    String? error,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      selectedRoomId: selectedRoomId ?? this.selectedRoomId,
      widgets: widgets ?? this.widgets,
      error: error,
    );
  }

  /// widgets ที่ "แสดงบนหน้า home"
  /// - ตัด inactive ออก (inactive = เก็บเข้าลิ้นชัก)
  /// - sort ให้ stable
  List<DeviceWidget> get visibleWidgets {
    final base = widgets.where((w) => w.status != 'inactive').toList();

    base.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      // fallback stable
      return a.widgetId.compareTo(b.widgetId);
    });

    return base;
  }

  /// widgets ที่ "อยู่ในลิ้นชัก"
  List<DeviceWidget> get drawerWidgets {
    final base = widgets.where((w) => w.status == 'inactive').toList();
    base.sort((a, b) => a.order.compareTo(b.order));
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
