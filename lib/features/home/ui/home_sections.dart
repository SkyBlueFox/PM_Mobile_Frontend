import 'home_view_model.dart';

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
        return 'ความสว่าง';
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
  /// หลัก: ถ้าไม่มีข้อมูลจริง => return false (ไม่แสดงการ์ดว่าง)
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
