import '../bloc/devices_state.dart';
import '../models/device_widget.dart';

/// ViewModel สำหรับ “Sensor 1 ตัว” (Read-only)
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

/// ViewModel สำหรับ “Toggle 1 ตัว”
/// NOTE: ไม่มี fallback => ถ้ามีรายการ แปลว่ามาจาก API จริง ๆ ดังนั้น widgetId ไม่ควรเป็น null
class HomeToggleVM {
  final String label;
  final bool isOn;
  final int widgetId;

  const HomeToggleVM({
    required this.label,
    required this.isOn,
    required this.widgetId,
  });
}

/// ViewModel สำหรับ “Adjust 1 ตัว” (เช่น color/brightness)
/// NOTE: อาจเป็น null ได้ เพราะ section จะถูกซ่อนไว้เมื่อไม่มี id
class HomeAdjustVM {
  final int? widgetId;
  const HomeAdjustVM({required this.widgetId});
}

/// แปลง DevicesState -> ข้อมูลที่ UI ต้องใช้
/// หลักการ: 
/// - ไม่สร้าง placeholder/fallback
/// - ถ้าไม่มีข้อมูลจริง -> list ว่าง / widgetId null -> แล้วให้ UI “ไม่ render section”
class HomeViewModel {
  final List<HomeSensorVM> sensors; // capability id = 3
  final List<HomeToggleVM> toggles; // capability id = 1
  final HomeAdjustVM colorAdjust; // capability id = 2 ตัวที่ 1
  final HomeAdjustVM brightnessAdjust; // capability id = 2 ตัวที่ 2

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

  factory HomeViewModel.fromState(DevicesState st) {
    final widgets = st.visibleWidgets;

    // ดึงตาม capability (ใช้ข้อมูลจริงเท่านั้น)
    final infos = widgets.where((w) => w.capability.id == 3).toList();
    final togglesW = widgets.where((w) => w.capability.id == 1).toList();
    final adjusts = widgets.where((w) => w.capability.id == 2).toList();

    return HomeViewModel(
      sensors: infos.map(_sensorFrom).toList(),
      toggles: togglesW.map(_toggleFrom).toList(),
      // ถ้าไม่มี adjust จริง -> widgetId เป็น null และ UI จะ “ไม่โชว์ section”
      colorAdjust: HomeAdjustVM(widgetId: adjusts.isNotEmpty ? adjusts[0].widgetId : null),
      brightnessAdjust: HomeAdjustVM(widgetId: adjusts.length > 1 ? adjusts[1].widgetId : null),
      isLoading: st.isLoading,
      error: st.error,
    );
  }

  /// Flags สำหรับให้ UI ตัดสินใจ “โชว์/ไม่โชว์ section”
  bool get hasSensors => sensors.isNotEmpty;
  bool get hasDevices => toggles.isNotEmpty;
  bool get hasColor => colorAdjust.widgetId != null;
  bool get hasBrightness => brightnessAdjust.widgetId != null;

  /// ตอนนี้ extra ไม่ผูกกับ API => ให้ซ่อนไว้เพื่อไม่ทำ fallback
  bool get hasExtra => false;

  static HomeSensorVM _sensorFrom(DeviceWidget w) {
    return HomeSensorVM(
      label: w.device.name,
      valueText: _fmt(w.value),
      unit: _guessUnit(w.device.name),
    );
  }

  static HomeToggleVM _toggleFrom(DeviceWidget w) {
    return HomeToggleVM(
      label: w.device.name,
      isOn: w.value >= 1,
      widgetId: w.widgetId,
    );
  }

  static String _fmt(double v) =>
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(1);

  /// เดายูนิตจากชื่อ (ถ้าเดาไม่ได้ให้เป็น '' เพื่อไม่ใส่ unit เกินจริง)
  static String _guessUnit(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('temp') || n.contains('อุณ') || n.contains('celsius')) return '°C';
    if (n.contains('hum') || n.contains('ความชื้น')) return '%';
    if (n.contains('lux') || n.contains('light') || n.contains('แสง')) return 'lux';
    return '';
  }
}
