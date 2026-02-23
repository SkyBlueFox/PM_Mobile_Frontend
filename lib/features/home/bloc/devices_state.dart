// lib/features/home/bloc/devices_state.dart
//
// ✅ devices_state.dart (ครบทั้งไฟล์)
// - คงโครงเดิม
// - เพิ่ม helper visibleWidgets / drawerWidgets (ใช้ status include/exclude)
// - ปลอดภัยกับ copyWith และ reorder flags

import '../models/device_widget.dart';
import '../models/room.dart';
import '../models/device.dart';

enum RoomActionStatus { idle, saving, success, failure }

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

  final RoomActionStatus roomActionStatus;
  final String? roomActionError;

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
    this.roomActionStatus = RoomActionStatus.idle,
    this.roomActionError,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    int? selectedRoomId,
    List<DeviceWidget>? widgets,
    String? error,
    List<Device>? devices,
    bool? reorderEnabled,
    bool? reorderSaving,
    List<int>? reorderOriginalVisibleIds,
    List<int>? reorderWorkingVisibleIds,
    RoomActionStatus? roomActionStatus,
    String? roomActionError,
    bool clearRoomActionError = false,
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
      roomActionStatus: roomActionStatus ?? this.roomActionStatus,
      roomActionError:
          clearRoomActionError ? null : (roomActionError ?? this.roomActionError),
    );
  }

  bool _isInclude(DeviceWidget w) => w.status.trim().toLowerCase() == 'include';

  /// widgets ที่ "แสดงบนหน้า home" = include เท่านั้น
  List<DeviceWidget> get visibleWidgets {
    final base = widgets.where(_isInclude).toList();
    base.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.widgetId.compareTo(b.widgetId);
    });
    return base;
  }

  /// widgets ที่ "อยู่ในลิ้นชัก" = exclude
  List<DeviceWidget> get drawerWidgets {
    final base = widgets.where((w) => !_isInclude(w)).toList();
    base.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.widgetId.compareTo(b.widgetId);
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