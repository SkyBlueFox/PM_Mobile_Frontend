// lib/features/home/ui/widgets/home_widget_grid.dart

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

  const HomeWidgetGrid({
    super.key,
    required this.tiles,
    required this.reorderEnabled,
    required this.onOrderChanged,
    required this.onToggle,
    required this.onAdjust,
    required this.onOpenSensor,
  });

  @override
  State<HomeWidgetGrid> createState() => _HomeWidgetGridState();
}

class _HomeWidgetGridState extends State<HomeWidgetGrid> {
  late List<HomeWidgetTileVM> _tiles;

  @override
  void initState() {
    super.initState();
    _tiles = List<HomeWidgetTileVM>.from(widget.tiles);
  }

  @override
  void didUpdateWidget(covariant HomeWidgetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // sync จาก bloc -> UI (กัน reorder ค้าง)
    if (oldWidget.tiles != widget.tiles) {
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

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

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
              final card = SizedBox(
                width: width,
                child: WidgetCard(
                  tile: t,
                  showDragHint: widget.reorderEnabled,
                  onToggle: locked ? () {} : () => widget.onToggle(t.widgetId),
                  onAdjust: locked ? (_) {} : (v) => widget.onAdjust(t.widgetId, v),
                  onOpenSensor: locked ? () {} : () => widget.onOpenSensor(t),
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
