// lib/features/home/ui/widgets/home_sections.dart
//
// ✅ Fix: HomeViewModel ไม่มี hasSensors/hasDevices/... แล้ว
// => ทำเป็น extension ในไฟล์นี้ให้เรียกได้เหมือนเดิม (ไม่กระทบส่วนอื่น)

import 'view_models/home_view_model.dart';

enum HomeSection {
  sensors,
  devices,
  color,
  brightness,
  extra,
}

extension HomeSectionX on HomeSection {
  String get title {
    switch (this) {
      case HomeSection.sensors:
        return 'Sensors';
      case HomeSection.devices:
        return 'Devices';
      case HomeSection.color:
        return 'Color';
      case HomeSection.brightness:
        return 'Brightness';
      case HomeSection.extra:
        return '';
    }
  }

  String get actionText {
    switch (this) {
      case HomeSection.sensors:
      case HomeSection.devices:
        return 'แก้ไข';
      case HomeSection.color:
      case HomeSection.brightness:
      case HomeSection.extra:
        return '';
    }
  }

  /// จุดเดียวที่กำหนดว่า section ไหน “ควรถูก render”
  /// หลัก: ถ้าไม่มีข้อมูลจริง => false (ไม่แสดงการ์ดว่าง)
  bool hasData(HomeViewModel vm) {
    switch (this) {
      case HomeSection.sensors:
        return vm.hasSensors;
      case HomeSection.devices:
        return vm.hasDevices;
      case HomeSection.color:
        return vm.hasColor;
      case HomeSection.brightness:
        return vm.hasBrightness;
      case HomeSection.extra:
        return vm.hasExtra;
    }
  }
}

/// ✅ เพิ่ม getters ให้ HomeViewModel ผ่าน extension (แก้ error hasSensors/hasDevices/...)
extension HomeViewModelSectionX on HomeViewModel {
  bool get hasSensors => tiles.any((t) => t.kind == HomeTileKind.sensor);

  bool get hasDevices => tiles.any((t) => t.kind == HomeTileKind.toggle);

  bool get hasBrightness => tiles.any(
        (t) => t.kind == HomeTileKind.adjust && _isBrightnessLike(t.title),
      );

  bool get hasColor => tiles.any(
        (t) =>
            t.kind == HomeTileKind.adjust &&
            t.showColorBar &&
            !_isBrightnessLike(t.title),
      );

  bool get hasExtra => tiles.any(
        (t) =>
            t.kind == HomeTileKind.adjust &&
            !t.showColorBar &&
            !_isBrightnessLike(t.title),
      );
}

bool _isBrightnessLike(String name) {
  final n = name.toLowerCase();
  return n.contains('bright') || n.contains('brightness') || n.contains('ความสว่าง');
}
