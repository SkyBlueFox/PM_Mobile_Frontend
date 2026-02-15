// lib/features/home/bloc/devices_state.dart
//
// State for DevicesBloc.
// หลักการ: state เป็น immutable, copyWith ชัดเจน (KISS)
// เอา class ซ้ำออก (ของเดิมคุณมีซ้ำ 2 ชุด)

import '../models/device_widget.dart';
import '../models/room.dart';
import '../models/device.dart';

class DevicesState {
  final bool isLoading;
  final List<Room> rooms;
  final int? selectedRoomId;
  final List<DeviceWidget> widgets;
  final String? error;
  final List<Device>? devices;

  final bool reorderEnabled;
  final bool reorderSaving;
  final List<int> reorderOriginalVisibleIds;
  final List<int> reorderWorkingVisibleIds;

  const DevicesState({
    this.isLoading = false,
    this.rooms = const [],
    this.selectedRoomId,
    this.widgets = const [],
    this.error,
    this.devices = const [],
    this.reorderEnabled = false,
    this.reorderSaving = false,
    this.reorderOriginalVisibleIds = const [],
    this.reorderWorkingVisibleIds = const [],
  });

  DevicesState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    int? selectedRoomId, // allow null
    List<DeviceWidget>? widgets,
    String? error,
    List<Device>? devices,
    bool? reorderEnabled,
    bool? reorderSaving,
    List<int>? reorderOriginalVisibleIds,
    List<int>? reorderWorkingVisibleIds,    
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      selectedRoomId: selectedRoomId ?? this.selectedRoomId,
      widgets: widgets ?? this.widgets,
      error: error,
      devices: devices ?? this.devices,
      reorderEnabled: reorderEnabled ?? this.reorderEnabled,
      reorderSaving: reorderSaving ?? this.reorderSaving,
      reorderOriginalVisibleIds:
          reorderOriginalVisibleIds ?? this.reorderOriginalVisibleIds,
      reorderWorkingVisibleIds:
          reorderWorkingVisibleIds ?? this.reorderWorkingVisibleIds,
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

  bool get reorderLocked => reorderEnabled || reorderSaving;

  bool get reorderDirty {
    final a = reorderWorkingVisibleIds;
    final b = reorderOriginalVisibleIds;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
}
