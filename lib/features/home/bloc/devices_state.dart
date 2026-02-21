// lib/features/home/bloc/devices_state.dart
//
// State for DevicesBloc.
// - เพิ่ม state สำหรับหน้าเลือก include/exclude (loading/saving + snapshot ของสถานะเดิม)
// - visibleWidgets เรียงตาม widgetId ตาม requirement

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

  // reorder
  final bool reorderEnabled;
  final bool reorderSaving;
  final List<int> reorderOriginalVisibleIds;
  final List<int> reorderWorkingVisibleIds;

  // include/exclude selection (widget picker)
  final bool selectionLoading;
  final bool selectionSaving;

  /// snapshot ของ status ตอนเริ่มเปิดหน้า picker เพื่อรู้ว่าอะไร "เปลี่ยนจริง"
  /// key: widgetId, value: status เดิม (เช่น 'active'/'inactive')
  final Map<int, String> selectionOriginalStatusById;

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

    this.selectionLoading = false,
    this.selectionSaving = false,
    this.selectionOriginalStatusById = const {},
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

    bool? selectionLoading,
    bool? selectionSaving,
    Map<int, String>? selectionOriginalStatusById,
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

      selectionLoading: selectionLoading ?? this.selectionLoading,
      selectionSaving: selectionSaving ?? this.selectionSaving,
      selectionOriginalStatusById:
          selectionOriginalStatusById ?? this.selectionOriginalStatusById,
    );
  }

  /// widgets ที่ "แสดงบนหน้า home"
  /// - include = status != 'inactive'
  /// - sort ตาม widgetId (ascending) ตาม requirement
  List<DeviceWidget> get visibleWidgets {
    final base = widgets.where((w) => w.status != 'inactive').toList();
    base.sort((a, b) => a.widgetId.compareTo(b.widgetId));
    return base;
  }

  /// widgets ที่ "exclude/อยู่ในลิ้นชัก"
  List<DeviceWidget> get drawerWidgets {
    final base = widgets.where((w) => w.status == 'inactive').toList();
    base.sort((a, b) => a.widgetId.compareTo(b.widgetId));
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