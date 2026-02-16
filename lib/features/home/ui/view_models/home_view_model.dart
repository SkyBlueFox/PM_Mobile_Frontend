// lib/features/home/ui/view_models/home_view_model.dart

import '../../../home/models/capability.dart';
import '../../../home/bloc/devices_state.dart';

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

  // sensor/adjust display
  final int intValue; // ให้ UI โชว์ “จำนวนเต็ม”
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
    required this.intValue,
    required this.unit,
    required this.min,
    required this.max,
    required this.showColorBar,
  });

  // ต้องเป็น "ตัวเลขล้วน" เพื่อให้ UI/Slider แปลงเป็นตัวเลขได้
  String get displayValue => '$intValue';
}

class HomeViewModel {
  final List<HomeWidgetTileVM> tiles; // ใช้ render หน้า Home (เฉพาะ visible)
  final bool isLoading;
  final String? error;

  // ✅ สำหรับลิ้นชัก: include/exclude
  final List<HomeWidgetTileVM> activeTiles;
  final List<HomeWidgetTileVM> drawerTiles;

  const HomeViewModel({
    required this.tiles,
    required this.isLoading,
    required this.error,
    List<HomeWidgetTileVM>? activeTiles,
    List<HomeWidgetTileVM>? drawerTiles,
  })  : activeTiles = activeTiles ?? tiles,
        drawerTiles = drawerTiles ?? const [];

  factory HomeViewModel.fromState(DevicesState st) {
    // visible (include)
    final visibleWidgets = st.visibleWidgets;
    final visibleIds = visibleWidgets.map((w) => w.widgetId).toSet();

    // all (include + exclude) — ถ้า backend ส่งมาแค่ visible จริง ๆ ฝั่ง exclude จะว่างเอง
    final allWidgets = st.widgets;

    final activeTiles = visibleWidgets.map(_toTile).toList();

    final drawerTiles = allWidgets
        .where((w) => !visibleIds.contains(w.widgetId))
        .map(_toTile)
        .toList();

    return HomeViewModel(
      tiles: activeTiles, // หน้า Home ใช้เฉพาะ include
      activeTiles: activeTiles,
      drawerTiles: drawerTiles,
      isLoading: st.isLoading,
      error: st.error,
    );
  }

  bool get isEmpty => tiles.isEmpty;

  // === Section grouping (ใช้กับ home_sections.dart) ===
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
    final cap = w.capability as Capability;
    final title = w.device.name as String;
    final subtitle = _capLabel(cap);

    final double? doubleValue = double.tryParse(w.value.toString());
    final int intValue = doubleValue?.round() ?? 0;

    if (cap.type == CapabilityType.info) {
      return HomeWidgetTileVM(
        widgetId: w.widgetId,
        title: title,
        subtitle: subtitle,
        span: HomeTileSpan.half,
        kind: HomeTileKind.sensor,
        isOn: false,
        intValue: intValue,
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
        intValue: intValue,
        unit: '',
        min: 0,
        max: 1,
        showColorBar: false,
      );
    }

    // adjust
    return HomeWidgetTileVM(
      widgetId: w.widgetId,
      title: title,
      subtitle: subtitle,
      span: HomeTileSpan.full,
      kind: HomeTileKind.adjust,
      isOn: false,
      intValue: intValue,
      unit: _guessAdjustUnit(title),
      min: 0,
      max: 100,
      showColorBar: _isColorLike(title),
    );
  }

  static String _capLabel(Capability cap) {
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
