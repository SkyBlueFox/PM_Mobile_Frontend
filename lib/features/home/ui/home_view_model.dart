import '../bloc/devices_state.dart';
import '../models/device_widget.dart';

class HomeSensorVM {
  final String label;
  final String valueText;
  final String unit;

  const HomeSensorVM({
    required this.label,
    required this.valueText,
    required this.unit,
  });
}

class HomeToggleVM {
  final String label;
  final bool isOn;

  /// null = โหมดทำ UI (ไม่ยิง event)
  final int? widgetId;

  const HomeToggleVM({
    required this.label,
    required this.isOn,
    required this.widgetId,
  });
}

class HomeAdjustVM {
  /// null = โหมดทำ UI (ไม่ยิง event)
  final int? widgetId;

  const HomeAdjustVM({required this.widgetId});
}

class HomeViewModel {
  final List<HomeSensorVM> sensors; // 2 ตัว
  final List<HomeToggleVM> toggles; // 2 ตัว
  final HomeAdjustVM colorAdjust;
  final HomeAdjustVM brightnessAdjust;

  /// ใช้เพื่อโชว์ banner แต่ไม่บล็อก UI
  final bool isLoading;
  final String? error;

  const HomeViewModel({
    required this.sensors,
    required this.toggles,
    required this.colorAdjust,
    required this.brightnessAdjust,
    required this.isLoading,
    required this.error,
  });

  // factory HomeViewModel.fromState(DevicesState st) {
  //   final widgets = st.visibleWidgets;

  //   final infos = widgets.where((w) => w.capability.id == 3).toList();
  //   final toggles = widgets.where((w) => w.capability.id == 1).toList();
  //   final adjusts = widgets.where((w) => w.capability.id == 2).toList();

  //   final a = infos.isNotEmpty ? infos[0] : null;
  //   final b = infos.length > 1 ? infos[1] : null;

  //   final led1 = toggles.isNotEmpty ? toggles[0] : null;
  //   final led2 = toggles.length > 1 ? toggles[1] : null;

  //   final adjustColor = adjusts.isNotEmpty ? adjusts[0] : null;
  //   final adjustBrightness = adjusts.length > 1 ? adjusts[1] : null;

  //   return HomeViewModel(
  //     sensors: [
  //       _sensorFrom(a, fallbackLabel: 'Sensor A'),
  //       _sensorFrom(b, fallbackLabel: 'Sensor B', fallbackUnit: '°C'),
  //     ],
  //     toggles: [
  //       _toggleFrom(led1, fallbackLabel: 'LED 1', fallbackOn: true),
  //       _toggleFrom(led2, fallbackLabel: 'LED 2', fallbackOn: false),
  //     ],
  //     colorAdjust: HomeAdjustVM(widgetId: adjustColor?.widgetId),
  //     brightnessAdjust: HomeAdjustVM(widgetId: adjustBrightness?.widgetId),
  //     isLoading: st.isLoading,
  //     error: st.error,
  //   );
  // }

  // static HomeSensorVM _sensorFrom(
  //   DeviceWidget? w, {
  //   required String fallbackLabel,
  //   String fallbackUnit = 'lux',
  // }) {
  //   if (w == null) {
  //     return HomeSensorVM(label: fallbackLabel, valueText: '26', unit: fallbackUnit);
  //   }
  //   return HomeSensorVM(
  //     label: w.device.name,
  //     valueText: _fmt(w.value),
  //     unit: _guessUnit(w.device.name, fallback: fallbackUnit),
  //   );
  // }

  // static HomeToggleVM _toggleFrom(
  //   DeviceWidget? w, {
  //   required String fallbackLabel,
  //   required bool fallbackOn,
  // }) {
  //   if (w == null) {
  //     return HomeToggleVM(label: fallbackLabel, isOn: fallbackOn, widgetId: null);
  //   }
  //   return HomeToggleVM(
  //     label: w.device.name,
  //     isOn: w.value >= 1,
  //     widgetId: w.widgetId,
  //   );
  // }

  factory HomeViewModel.fromState(DevicesState st) {
  final widgets = st.visibleWidgets;

  final infos = widgets.where((w) => w.capability.id == 3).toList();
  final togglesW = widgets.where((w) => w.capability.id == 1).toList();
  final adjusts = widgets.where((w) => w.capability.id == 2).toList();

  return HomeViewModel(
    sensors: infos.map(_sensorFromNoFallback).toList(),
    toggles: togglesW.map(_toggleFromNoFallback).toList(),
    colorAdjust: HomeAdjustVM(widgetId: adjusts.isNotEmpty ? adjusts[0].widgetId : null),
    brightnessAdjust: HomeAdjustVM(widgetId: adjusts.length > 1 ? adjusts[1].widgetId : null),
    isLoading: st.isLoading,
    error: st.error,
  );
}

static HomeSensorVM _sensorFromNoFallback(DeviceWidget w) {
  return HomeSensorVM(
    label: w.device.name,
    valueText: _fmt(w.value),
    unit: _guessUnit(w.device.name, fallback: ''),
  );
}

static HomeToggleVM _toggleFromNoFallback(DeviceWidget w) {
  return HomeToggleVM(
    label: w.device.name,
    isOn: w.value >= 1,
    widgetId: w.widgetId,
  );
}


  static String _fmt(double v) =>
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(1);

  static String _guessUnit(String? name, {required String fallback}) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('temp') || n.contains('อุณ') || n.contains('celsius')) return '°C';
    if (n.contains('hum') || n.contains('ความชื้น')) return '%';
    if (n.contains('lux') || n.contains('light') || n.contains('แสง')) return 'lux';
    return fallback;
  }
}
