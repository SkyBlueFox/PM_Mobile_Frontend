import '../models/device.dart';

class DevicesState {
  final bool isLoading;

  /// แท็บด้านบน (ทั้งหมด/ห้องนอน/ห้องนั่งเล่น)
  final RoomType selectedTab;

  /// dropdown ใน section
  final RoomType selectedRoom;

  /// รายการ device ทั้งหมด (รองรับหลายชนิด)
  final List<Device> devices;

  final String? error;

  const DevicesState({
    this.isLoading = false,
    this.selectedTab = RoomType.all,
    this.selectedRoom = RoomType.bedroom,
    this.devices = const [],
    this.error,
  });

  DevicesState copyWith({
    bool? isLoading,
    RoomType? selectedTab,
    RoomType? selectedRoom,
    List<Device>? devices,
    String? error,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      devices: devices ?? this.devices,
      error: error,
    );
  }

  RoomType get _effectiveRoomFilter {
    // ถ้า tab เป็น “ทั้งหมด” ให้ dropdown เป็นตัวกรองหลัก
    if (selectedTab == RoomType.all) return selectedRoom;
    return selectedTab;
  }

  List<Device> get visibleDevices {
    final roomFilter = _effectiveRoomFilter;
    if (roomFilter == RoomType.all) return devices;
    return devices.where((d) => d.room == roomFilter).toList();
  }

  int get deviceCount => visibleDevices.length;
}
