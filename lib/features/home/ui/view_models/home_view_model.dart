// lib/features/home/ui/view_models/home_view_model.dart
//
// ปรับให้มี include/exclude จริง:
// - tiles = include (จาก state.visibleWidgets)
// - drawerTiles = exclude (state.widgets - visibleWidgets)

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
  final int intValue;
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

  String get displayValue => '$intValue';
}

class HomeViewModel {
  final List<HomeWidgetTileVM> tiles; // include
  final List<HomeWidgetTileVM> drawerTiles; // exclude
  final bool isLoading;
  final String? error;

  const HomeViewModel({
    required this.tiles,
    required this.drawerTiles,
    required this.isLoading,
    required this.error,
  });

  factory HomeViewModel.fromState(DevicesState st) {
    final includedWidgets = st.visibleWidgets;
    final includedIds = includedWidgets.map((w) => w.widgetId).toSet();

    final excludedWidgets = st.widgets.where((w) => !includedIds.contains(w.widgetId)).toList();

    final includedTiles = includedWidgets.map(_mapWidgetToTile).toList();
    final excludedTiles = excludedWidgets.map(_mapWidgetToTile).toList();

    return HomeViewModel(
      tiles: includedTiles,
      drawerTiles: excludedTiles,
      isLoading: st.isLoading,
      error: st.error,
    );
  }

  bool get isEmpty => tiles.isEmpty;

  // ใช้ชื่อเดิมให้ home_page เรียกง่าย
  List<HomeWidgetTileVM> get activeTiles => tiles;

  static HomeWidgetTileVM _mapWidgetToTile(dynamic w) {
    final cap = w.capability;

    final title = w.device.name as String;
    final subtitle = _capLabel(cap);

    final doubleValue = double.tryParse(w.value.toString());
    final intValue = doubleValue?.round() ?? 0;

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

  static String _capLabel(Capability cap) => 'cap';

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
}
