import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/watermark_position.dart';

class WatermarkTransform {
  const WatermarkTransform({required this.position, required this.scale});
  final WatermarkPosition position;
  final double scale;
}

class DraggableWatermarkOverlay extends StatefulWidget {
  const DraggableWatermarkOverlay({
    super.key,
    required this.position,
    required this.margin,
    required this.quarterTurns,
    required this.onChanged,
    required this.onLayout,
    required this.child,
    this.scale = 1,
    this.draggable = true,
  });

  final WatermarkPosition position;
  final double margin;
  final int quarterTurns;
  final ValueChanged<WatermarkTransform> onChanged;
  final void Function(Size size, WatermarkTransform transform) onLayout;
  final Widget child;
  final double scale;
  final bool draggable;

  @override
  State<DraggableWatermarkOverlay> createState() =>
      _DraggableWatermarkOverlayState();
}

class _DraggableWatermarkOverlayState extends State<DraggableWatermarkOverlay> {
  final _stackKey = GlobalKey();
  final _watermarkKey = GlobalKey();
  Size _baseSize = Size.zero;
  Size _area = Size.zero;
  Offset? _gestureOffset;
  double? _gestureScale;
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1;
  int _pointerCount = 0;
  bool _measurePending = false;
  final Map<int, Offset> _pointers = {};
  Offset? _configurationFocal;

  void _rebasePointers() {
    _configurationFocal = _pointers.isEmpty
        ? null
        : _local(
            _pointers.values.reduce((a, b) => a + b) /
                _pointers.length.toDouble(),
          );
  }

  void _finishGesture() {
    if (_gestureOffset == null) return;
    final transform = _transform(_fitScale(_gestureScale ?? widget.scale));
    widget.onChanged(transform);
    setState(() {
      _gestureOffset = null;
      _gestureScale = null;
    });
  }

  void _releasePointer(int pointer) {
    _pointers.remove(pointer);
    _rebasePointers();
    if (_pointers.isEmpty) _finishGesture();
  }

  @override
  void didUpdateWidget(DraggableWatermarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quarterTurns != widget.quarterTurns || !widget.draggable) {
      _gestureOffset = null;
      _gestureScale = null;
    }
  }

  double _fitScale(double requested) {
    if (_baseSize.isEmpty || _area.isEmpty) return 1;
    final maxScale = math.max(
      .001,
      math.min(
        3.0,
        math.min(
          (_area.width - widget.margin * 2) / _baseSize.width,
          (_area.height - widget.margin * 2) / _baseSize.height,
        ),
      ),
    );
    return requested.clamp(math.min(.25, maxScale), maxScale);
  }

  Offset _clamp(Offset value, Size size) => Offset(
    value.dx.clamp(
      widget.margin,
      math.max(widget.margin, _area.width - size.width - widget.margin),
    ),
    value.dy.clamp(
      widget.margin,
      math.max(widget.margin, _area.height - size.height - widget.margin),
    ),
  );

  Offset _offset(double scale) {
    final size = _baseSize * scale;
    return _clamp(
      _gestureOffset ??
          widget.position.resolve(_area, size, margin: widget.margin),
      size,
    );
  }

  WatermarkTransform _transform(double scale) => WatermarkTransform(
    position: WatermarkPosition.fromOffset(
      _offset(scale),
      _area,
      _baseSize * scale,
      margin: widget.margin,
    ),
    scale: scale,
  );

  void _scheduleMeasure() {
    if (_measurePending) return;
    _measurePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurePending = false;
      if (!mounted) return;
      final box =
          _watermarkKey.currentContext?.findRenderObject() as RenderBox?;
      final next = box?.size ?? Size.zero;
      if (next.isEmpty) return;
      if (next != _baseSize) {
        setState(() => _baseSize = next);
      }
      final scale = _fitScale(_gestureScale ?? widget.scale);
      widget.onLayout(_baseSize * scale, _transform(scale));
    });
  }

  Offset _local(Offset global) =>
      (_stackKey.currentContext!.findRenderObject() as RenderBox).globalToLocal(
        global,
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _area = constraints.biggest;
      _scheduleMeasure();
      final scale = _fitScale(_gestureScale ?? widget.scale);
      final offset = _offset(scale);
      final content = RepaintBoundary(
        child: RotatedBox(
          key: _watermarkKey,
          quarterTurns: widget.quarterTurns,
          child: widget.child,
        ),
      );
      return Stack(
        key: _stackKey,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: offset.dx,
            top: offset.dy,
            child: Semantics(
              hint:
                  'Drag to move. Pinch with two fingers to resize the watermark.',
              child: Listener(
                onPointerDown: (event) {
                  _pointers[event.pointer] = event.position;
                  _rebasePointers();
                },
                onPointerMove: (event) =>
                    _pointers[event.pointer] = event.position,
                onPointerUp: (event) => _releasePointer(event.pointer),
                onPointerCancel: (event) => _releasePointer(event.pointer),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: !widget.draggable
                      ? null
                      : (details) {
                          _gestureOffset ??= offset;
                          _gestureScale ??= scale;
                          _lastFocalPoint =
                              _configurationFocal ?? _local(details.focalPoint);
                          _lastScale = 1;
                          _pointerCount = details.pointerCount;
                        },
                  onScaleUpdate: !widget.draggable
                      ? null
                      : (details) {
                          if (_gestureOffset == null || _gestureScale == null) {
                            return;
                          }
                          final focal = _local(details.focalPoint);
                          // Adding/removing a finger changes the focal point. Rebase without
                          // moving the watermark so switching between drag and pinch is smooth.
                          if (_pointerCount != details.pointerCount) {
                            _pointerCount = details.pointerCount;
                            _lastFocalPoint = focal;
                            _lastScale = details.scale;
                            return;
                          }
                          final previousScale = _gestureScale!;
                          final ratio =
                              details.pointerCount > 1 && _lastScale > 0
                              ? details.scale / _lastScale
                              : 1.0;
                          final nextScale = _fitScale(previousScale * ratio);
                          final nextOffset =
                              focal -
                              (_lastFocalPoint - _gestureOffset!) *
                                  (nextScale / previousScale);
                          setState(() {
                            _gestureScale = nextScale;
                            _gestureOffset = _clamp(
                              nextOffset,
                              _baseSize * nextScale,
                            );
                          });
                          _lastFocalPoint = focal;
                          _lastScale = details.scale;
                        },
                  onScaleEnd: !widget.draggable
                      ? null
                      : (details) {
                          if (details.pointerCount == 0) _finishGesture();
                        },
                  child: _baseSize.isEmpty
                      ? Opacity(opacity: 0, child: content)
                      : SizedBox.fromSize(
                          size: _baseSize * scale,
                          child: FittedBox(
                            alignment: Alignment.topLeft,
                            child: content,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
