// lib/features/home/ui/view_models/home_view_model.dart
//
// ✅ FIX (safe): ปรับการเดา unit ให้ "ยึด cap/subtitle" ก่อน (แม่นกว่าเดาจากชื่อ device)
// - ไม่กระทบ bloc / repository
// - ไม่เปลี่ยน public interface ของ VM ที่ UI ใช้อยู่
//
// หมายเหตุ:
// - title = ชื่อ device
// - subtitle = ชื่อ cap (เช่น sensor/toggle/adjust หรือ label ตาม capability)

import '../../bloc/devices_state.dart';
import '../../models/capability.dart';

enum HomeTileSpan { half, full }

enum HomeTileKind {
  sensor,
  toggle,
  adjust,

  // ✅ เพิ่มให้ครบ
  mode,
  text,
  button,
}

class HomeWidgetTileVM {
  final int widgetId;

  final String title;
  final String subtitle;

  final HomeTileSpan span;
  final HomeTileKind kind;

  // toggle
  final bool isOn;

  /// display value (ใช้กับ sensor/adjust/toggle เป็นหลัก)
  /// - sensor/adjust/toggle: ตัวเลข (string)
  /// - mode: ค่าปัจจุบัน เช่น "cool"
  /// - text: ค่าปัจจุบัน (ข้อความ)
  /// - button: อาจเป็น "" ได้
  final String value;

  final String unit;

  // adjust
  final int min;
  final int max;
  final bool showColorBar;

  // ✅ mode
  final List<String> modeOptions;

  // ✅ text
  final String hintText;

  // ✅ button
  final String buttonLabel;

  const HomeWidgetTileVM({
    required this.widgetId,
    required this.title,
    required this.subtitle,
    required this.span,
    required this.kind,
    required this.isOn,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.showColorBar,
    required this.modeOptions,
    required this.hintText,
    required this.buttonLabel,
  });

  String get displayValue => value;
}

class HomeViewModel {
  /// ใช้ render หน้า Home (เฉพาะ visible)
  /// NOTE: tiles == activeTiles เพื่อให้ไม่สับสน
  final List<HomeWidgetTileVM> tiles;
  final bool isLoading;
  final String? error;

  /// สำหรับลิ้นชัก include/exclude
  final List<HomeWidgetTileVM> activeTiles;
  final List<HomeWidgetTileVM> drawerTiles;

  const HomeViewModel({
    required this.tiles,
    required this.isLoading,
    required this.error,
    required this.activeTiles,
    required this.drawerTiles,
  });

  factory HomeViewModel.fromState(DevicesState st) {
    // ✅ ใช้ source ที่ "เรียงแล้ว" จาก DevicesState เพื่อให้ reorder เสถียร
    final visibleWidgets = st.visibleWidgets; // sorted by order then widgetId
    final drawerWidgets = st.drawerWidgets; // inactive only

    final activeTiles = visibleWidgets.map(_toTile).toList(growable: false);
    final drawerTiles = drawerWidgets.map(_toTile).toList(growable: false);

    return HomeViewModel(
      tiles: activeTiles,
      activeTiles: activeTiles,
      drawerTiles: drawerTiles,
      isLoading: st.isLoading,
      error: st.error,
    );
  }

  bool get isEmpty => tiles.isEmpty;

  // ---- mapping ----
  static HomeWidgetTileVM _toTile(dynamic w) {
    final Capability cap = w.capability as Capability;

    // title = device name (ตาม requirement)
    final String title = (w.device.name ?? '').toString();

    // subtitle = cap name/label (ตาม requirement)
    final String subtitle = _capLabel(cap);

    final String rawValue = (w.value ?? '').toString();

    // --- sensor ---
    if (cap.type == CapabilityType.sensor) {
      final int intValue = _toIntSafe(rawValue);

      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.sensor,
        isOn: false,
        value: intValue.toString(),
        // ✅ เดา unit จาก cap/subtitle ก่อน แล้วค่อย fallback จาก title
        unit: _guessSensorUnit(title: title, capLabel: subtitle),
        min: 0,
        max: 100,
        showColorBar: false,
        modeOptions: const [],
        hintText: '',
        buttonLabel: '',
      );
    }

    // --- toggle ---
    if (cap.type == CapabilityType.toggle) {
      final int intValue = _toIntSafe(rawValue);

      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.toggle,
        isOn: intValue >= 1,
        value: intValue.toString(),
        unit: '',
        min: 0,
        max: 1,
        showColorBar: false,
        modeOptions: const [],
        hintText: '',
        buttonLabel: '',
      );
    }

    // --- mode ---
    if (cap.type == CapabilityType.mode) {
      // ถ้ามี options ใน Capability ให้ใช้ (ถ้ายังไม่ได้เพิ่ม options ใน model ให้ปล่อย fallback)
      final List<String> options =
          (cap is dynamic && (cap as dynamic).options is List)
              ? List<String>.from(
                  (cap as dynamic).options.map((e) => e.toString()),
                )
              : const ['auto', 'cool', 'dry', 'fan', 'heat'];

      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.mode,
        isOn: false,
        value: rawValue, // string mode เช่น "cool"
        unit: '',
        min: 0,
        max: 0,
        showColorBar: false,
        modeOptions: options,
        hintText: '',
        buttonLabel: '',
      );
    }

    // --- text ---
    if (cap.type == CapabilityType.text) {
      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.full,
        kind: HomeTileKind.text,
        isOn: false,
        value: rawValue, // ข้อความล่าสุด (ถ้ามี)
        unit: '',
        min: 0,
        max: 0,
        showColorBar: false,
        modeOptions: const [],
        hintText: 'Enter text',
        buttonLabel: '',
      );
    }

    // --- button ---
    if (cap.type == CapabilityType.button) {
      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.button,
        isOn: false,
        value: '', // ปุ่มกดครั้งเดียว ไม่ต้องโชว์ value
        unit: '',
        min: 0,
        max: 0,
        showColorBar: false,
        modeOptions: const [],
        hintText: '',
        buttonLabel: 'Press',
      );
    }

    // --- adjust (default) ---
    final int intValue = _toIntSafe(rawValue);
    final int min = 0;
    final int max = 100;

    return HomeWidgetTileVM(
      widgetId: w.widgetId,
      title: title,
      subtitle: subtitle,
      span: HomeTileSpan.full,
      kind: HomeTileKind.adjust,
      isOn: false,
      value: intValue.toString(),
      // ✅ เดา unit จาก cap/subtitle ก่อน แล้วค่อย fallback จาก title
      unit: _guessAdjustUnit(title: title, capLabel: subtitle),
      min: min,
      max: max,
      showColorBar: _isColorLike(title),
      modeOptions: const [],
      hintText: '',
      buttonLabel: '',
    );
  }

  static int _toIntSafe(String s) {
    final double? d = double.tryParse(s);
    return d?.round() ?? 0;
  }

  static String _capLabel(Capability cap) {
    // ปรับ label ให้ตรงตาม type
    switch (cap.type) {
      case CapabilityType.sensor:
        return 'cap';
      case CapabilityType.toggle:
        return 'cap';
      case CapabilityType.adjust:
        return 'cap';
      case CapabilityType.mode:
        return 'cap';
      case CapabilityType.text:
        return 'cap';
      case CapabilityType.button:
        return 'cap';
      default:
        return 'cap';
    }
  }

  // ------------------------------
  // Unit helpers (safe, ไม่กระทบ logic อื่น)
  // ------------------------------

  static String _guessSensorUnit({
    required String title,
    required String capLabel,
  }) {
    // ✅ ให้ดู cap/subtitle ก่อน (มักบอกชนิดค่าชัดกว่า)
    final c = capLabel.toLowerCase();
    if (c.contains('temp') || c.contains('อุณ')) return '°C';
    if (c.contains('hum') || c.contains('ความชื้น')) return '%';
    if (c.contains('lux') || c.contains('light') || c.contains('แสง')) return 'lx';

    // fallback: ดูจากชื่อ device
    final n = title.toLowerCase();
    if (n.contains('temp') || n.contains('อุณ')) return '°C';
    if (n.contains('hum') || n.contains('ความชื้น')) return '%';
    if (n.contains('lux') || n.contains('light') || n.contains('แสง')) return 'lx';
    return '';
  }

  static String _guessAdjustUnit({
    required String title,
    required String capLabel,
  }) {
    final c = capLabel.toLowerCase();
    if (c.contains('bright') || c.contains('light') || c.contains('ความสว่าง')) return '%';
    if (c.contains('vol') || c.contains('sound')) return '%';

    final n = title.toLowerCase();
    if (n.contains('bright') || n.contains('light') || n.contains('ความสว่าง')) return '%';
    if (n.contains('vol') || n.contains('sound')) return '%';
    return '%';
  }

  static bool _isColorLike(String name) {
    final n = name.toLowerCase();
    return n.contains('color') || n.contains('temp') || n.contains('rgb');
  }

  static bool _isBrightnessLike(String name) {
    final n = name.toLowerCase();
    return n.contains('bright') ||
        n.contains('brightness') ||
        n.contains('ความสว่าง');
  }
}