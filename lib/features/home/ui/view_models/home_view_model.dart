// lib/features/home/ui/view_models/home_view_model.dart

import '../../../home/models/device_widget.dart';
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
  final List<HomeWidgetTileVM> tiles;
  final bool isLoading;
  final String? error;

  const HomeViewModel({
    required this.tiles,
    required this.isLoading,
    required this.error,
  });

  factory HomeViewModel.fromState(DevicesState st) {
    final widgets = st.visibleWidgets;

    final tiles = widgets.map((w) {
      final cap = w.capability;

      // title/subtitle ตามรูป: title = device name, subtitle = cap name/type
      final title = w.device.name;
      final subtitle = _capLabel(cap);

      final intValue = w.value.round(); // ✅ โชว์เป็นจำนวนเต็ม

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
          isOn: w.value >= 1,
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
    }).toList();

    return HomeViewModel(
      tiles: tiles,
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
      .where((t) =>
          t.kind == HomeTileKind.adjust &&
          t.showColorBar &&
          !_isBrightnessLike(t.title))
      .toList(growable: false);

  List<HomeWidgetTileVM> get extraTiles => tiles
      .where((t) =>
          t.kind == HomeTileKind.adjust &&
          !_isBrightnessLike(t.title) &&
          !t.showColorBar)
      .toList(growable: false);

  // getters ที่ home_sections.dart เรียกใช้
  bool get hasSensors => sensorTiles.isNotEmpty;
  bool get hasDevices => deviceTiles.isNotEmpty;
  bool get hasColor => colorTiles.isNotEmpty;
  bool get hasBrightness => brightnessTiles.isNotEmpty;
  bool get hasExtra => extraTiles.isNotEmpty;

  // เผื่อ UI เดิมเรียกใช้
  List<HomeWidgetTileVM> get activeTiles => tiles;
  List<HomeWidgetTileVM> get drawerTiles => tiles;

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
