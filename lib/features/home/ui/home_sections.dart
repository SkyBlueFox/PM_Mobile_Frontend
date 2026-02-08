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
}
