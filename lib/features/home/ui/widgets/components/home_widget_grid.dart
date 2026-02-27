// lib/features/home/ui/widgets/components/home_widget_grid.dart
//
// ✅ FIX UI: ทำให้ widget card "สูงเท่ากันทั้งหมด"
// - ต่างกันแค่ความกว้าง: half/full
// - ไม่ไปแตะ business logic / bloc
// - ใช้ SizedBox(height: kTileHeight) ครอบทุก card
//
// หมายเหตุ:
// - ถ้าภายในการ์ดมี layout สูงเกิน จะถูกบังคับให้ย่อลง/ตัดบรรทัดใน WidgetCard เอง

import 'dart:async';
import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';
import '../cards/widget_card.dart';

/// Grid ที่รองรับ 2 ขนาด (half/full) + drag reorder (ในโหมด edit)
/// ใช้ Wrap เพื่อรองรับ half-width 2 ช่องต่อแถวแบบง่าย (KISS)
class HomeWidgetGrid extends StatefulWidget {
  final List<HomeWidgetTileVM> tiles;

  /// เปิดโหมด reorder
  final bool reorderEnabled;

  /// เมื่อ order เปลี่ยน ให้ส่ง widgetIds เรียงใหม่กลับไปให้ Bloc
  final ValueChanged<List<int>> onOrderChanged;

  /// action ต่อ widget
  final ValueChanged<int> onToggle;
  final void Function(int widgetId, int value) onAdjust;
  final ValueChanged<HomeWidgetTileVM> onOpenSensor;

  // ✅ new kinds
  final ValueChanged<HomeWidgetTileVM> onOpenMode;
  final ValueChanged<HomeWidgetTileVM> onOpenText;
  final ValueChanged<int> onPressButton;

  const HomeWidgetGrid({
    super.key,
    required this.tiles,
    required this.reorderEnabled,
    required this.onOrderChanged,
    required this.onToggle,
    required this.onAdjust,
    required this.onOpenSensor,
    required this.onOpenMode,
    required this.onOpenText,
    required this.onPressButton,
  });

  @override
  State<HomeWidgetGrid> createState() => _HomeWidgetGridState();
}

class _HomeWidgetGridState extends State<HomeWidgetGrid> {
  late List<HomeWidgetTileVM> _tiles;

  final Map<int, Timer> _debounceTimers = {};
  final Map<int, int> _draftAdjustValues = {};

  @override
  void initState() {
    super.initState();
    _tiles = List<HomeWidgetTileVM>.from(widget.tiles);
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _debouncedAdjust(int widgetId, int value) {
    _debounceTimers[widgetId]?.cancel();
    _debounceTimers[widgetId] = Timer(const Duration(milliseconds: 400), () {
      widget.onAdjust(widgetId, value);
    });
  }

  @override
  void didUpdateWidget(covariant HomeWidgetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ sync จาก bloc -> UI
    // - ถ้า tiles เปลี่ยน (เช่น save include/exclude แล้วกลับหน้า home) ให้ replace
    // - ถ้า switch เข้า/ออกโหมด reorder ก็ยังใช้ลำดับจาก bloc (ห้าม sort ที่นี่)
    if (!identical(oldWidget.tiles, widget.tiles) ||
        oldWidget.reorderEnabled != widget.reorderEnabled) {
      _tiles = List<HomeWidgetTileVM>.from(widget.tiles);
    }
  }

  void _reorderById(int fromId, int toId) {
    final fromIndex = _tiles.indexWhere((t) => t.widgetId == fromId);
    final toIndex = _tiles.indexWhere((t) => t.widgetId == toId);
    if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;

    setState(() {
      final moved = _tiles.removeAt(fromIndex);
      _tiles.insert(toIndex, moved);
    });

    widget.onOrderChanged(_tiles.map((e) => e.widgetId).toList());
  }

  HomeWidgetTileVM _copyWithValue(HomeWidgetTileVM t, String newValue) {
    return HomeWidgetTileVM(
      widgetId: t.widgetId,
      title: t.title,
      subtitle: t.subtitle,
      span: t.span,
      kind: t.kind,
      isOn: t.isOn,
      value: newValue,
      unit: t.unit,
      min: t.min,
      max: t.max,
      showColorBar: t.showColorBar,
      modeOptions: t.modeOptions,
      hintText: t.hintText,
      buttonLabel: t.buttonLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

    // ✅ ความสูงมาตรฐานของทุก widget card
    // ปรับตัวเลขนี้ได้ตาม UI ที่ต้องการ
    const double kTileHeight = 86.0;

    return LayoutBuilder(
      builder: (context, c) {
        final fullW = c.maxWidth;
        final halfW = (fullW - gap) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 18),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: _tiles.map((t) {
              final width = (t.span == HomeTileSpan.full) ? fullW : halfW;
              final locked = widget.reorderEnabled;

              final effectiveValue = _draftAdjustValues.containsKey(t.widgetId)
                  ? _draftAdjustValues[t.widgetId]!.toString()
                  : t.value;

              final effectiveTile = (t.kind == HomeTileKind.adjust)
                  ? _copyWithValue(t, effectiveValue)
                  : t;

              // ✅ บังคับความสูงเท่ากันทุก card (full/half ต่างกันแค่ width)
              final card = SizedBox(
                width: width,
                height: kTileHeight,
                child: WidgetCard(
                  tile: effectiveTile,
                  showDragHint: widget.reorderEnabled,
                  onToggle: locked ? () {} : () => widget.onToggle(t.widgetId),
                  onAdjust: locked
                      ? (_) {}
                      : (v) {
                          setState(() {
                            _draftAdjustValues[t.widgetId] = v;
                          });
                          _debouncedAdjust(t.widgetId, v);
                        },
                  onOpenSensor: locked ? () {} : () => widget.onOpenSensor(t),
                  onOpenMode: locked ? () {} : () => widget.onOpenMode(t),
                  onOpenText: locked ? () {} : () => widget.onOpenText(t),
                  onPressButton:
                      locked ? () {} : () => widget.onPressButton(t.widgetId),
                ),
              );

              if (!widget.reorderEnabled) return card;

              // drag & drop แบบง่าย: ใช้ widgetId เป็น data
              return DragTarget<int>(
                onWillAccept: (fromId) => fromId != null && fromId != t.widgetId,
                onAccept: (fromId) => _reorderById(fromId, t.widgetId),
                builder: (context, candidate, rejected) {
                  final isHover = candidate.isNotEmpty;

                  return LongPressDraggable<int>(
                    data: t.widgetId,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(opacity: 0.92, child: card),
                    ),
                    childWhenDragging: Opacity(opacity: 0.35, child: card),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: isHover ? 0.98 : 1,
                      child: card,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}