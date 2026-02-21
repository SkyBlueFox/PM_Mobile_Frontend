// lib/features/home/ui/view_models/home_view_model.dart

import '../../bloc/devices_state.dart';
import '../../models/capability.dart';

enum HomeTileSpan { half, full }
enum HomeTileKind { sensor, toggle, adjust }

class HomeWidgetTileVM {
  final int widgetId;

  final String title;
  final String subtitle;

  final HomeTileSpan span;
  final HomeTileKind kind;

  // toggle
  final bool isOn;

  // sensor/adjust display (ต้องเป็นตัวเลขล้วน เพื่อให้ UI/Slider แปลงได้ชัวร์)
  final String value;
  final String unit;

  // adjust
  final int min;
  final int max;
  final bool showColorBar;

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
    final drawerWidgets = st.drawerWidgets;   // inactive only

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

  // === Section grouping (ใช้กับ home_sections.dart ถ้ายังใช้) ===
  List<HomeWidgetTileVM> get sensorTiles =>
      tiles.where((t) => t.kind == HomeTileKind.sensor).toList(growable: false);

  List<HomeWidgetTileVM> get deviceTiles =>
      tiles.where((t) => t.kind == HomeTileKind.toggle).toList(growable: false);

  List<HomeWidgetTileVM> get brightnessTiles => tiles
      .where((t) => t.kind == HomeTileKind.adjust && _isBrightnessLike(t.title))
      .toList(growable: false);

  List<HomeWidgetTileVM> get colorTiles => tiles
      .where((t) => t.kind == HomeTileKind.adjust && t.showColorBar && !_isBrightnessLike(t.title))
      .toList(growable: false);

  List<HomeWidgetTileVM> get extraTiles => tiles
      .where((t) => t.kind == HomeTileKind.adjust && !_isBrightnessLike(t.title) && !t.showColorBar)
      .toList(growable: false);

  bool get hasSensors => sensorTiles.isNotEmpty;
  bool get hasDevices => deviceTiles.isNotEmpty;
  bool get hasColor => colorTiles.isNotEmpty;
  bool get hasBrightness => brightnessTiles.isNotEmpty;
  bool get hasExtra => extraTiles.isNotEmpty;

  // ---- mapping ----
  static HomeWidgetTileVM _toTile(dynamic w) {
    final Capability cap = w.capability as Capability;
    final String title = (w.device.name ?? '').toString();
    final String subtitle = _capLabel(cap);

    // ✅ normalize ให้ value เป็น "เลขล้วน"
    final double? doubleValue = double.tryParse(w.value.toString());
    final int intValue = doubleValue?.round() ?? 0;

    if (cap.type == CapabilityType.sensor) {
      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.sensor,
        isOn: false,
        value: intValue.toString(),
        unit: _guessUnit(title),
        min: 0,
        max: 100,
        showColorBar: false,
      );
    }

    if (cap.type == CapabilityType.toggle) {
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
      );
    }

    // adjust
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
      unit: _guessAdjustUnit(title),
      min: min,
      max: max,
      showColorBar: _isColorLike(title),
    );
  }

  static String _capLabel(Capability cap) {
    // ถ้าจะให้สวยขึ้นค่อย map ตาม cap.type ได้
    return 'cap';
  }

  static String _guessUnit(String name) {
    final n = name.toLowerCase();
    if (n.contains('temp') || n.contains('อุณ')) return '°C';
    if (n.contains('hum') || n.contains('ความชื้น')) return '%';
    if (n.contains('lux') || n.contains('light') || n.contains('แสง')) return 'lx';
    return '';
  }

  static String _guessAdjustUnit(String name) {
    final n = name.toLowerCase();
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
    return n.contains('bright') || n.contains('brightness') || n.contains('ความสว่าง');
  }
}