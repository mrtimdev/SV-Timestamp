import 'dart:ui';

class WatermarkPosition {
  const WatermarkPosition({this.x = 0, this.y = 1});

  final double x;
  final double y;

  WatermarkPosition clamped() =>
      WatermarkPosition(x: x.clamp(0.0, 1.0), y: y.clamp(0.0, 1.0));

  Offset resolve(Size area, Size watermark, {double margin = 0}) {
    final availableWidth = (area.width - watermark.width - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    final availableHeight = (area.height - watermark.height - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    final value = clamped();
    return Offset(
      margin + availableWidth * value.x,
      margin + availableHeight * value.y,
    );
  }

  static WatermarkPosition fromOffset(
    Offset offset,
    Size area,
    Size watermark, {
    double margin = 0,
  }) {
    final availableWidth = (area.width - watermark.width - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    final availableHeight = (area.height - watermark.height - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    return WatermarkPosition(
      x: availableWidth == 0
          ? 0
          : ((offset.dx - margin) / availableWidth).clamp(0.0, 1.0),
      y: availableHeight == 0
          ? 0
          : ((offset.dy - margin) / availableHeight).clamp(0.0, 1.0),
    );
  }
}

class WatermarkCaptureLayout {
  const WatermarkCaptureLayout({
    required this.previewSize,
    required this.safeRect,
    required this.watermarkSize,
    required this.position,
    required this.margin,
    required this.mirrored,
    required this.quarterTurns,
    this.watermarkZoom = 1,
  });

  final Size previewSize;
  final Rect safeRect;
  final Size watermarkSize;

  /// Position in the upright photo, independent of the camera's mirroring.
  final WatermarkPosition position;
  final double margin;
  final bool mirrored;
  final int quarterTurns;

  /// Uniform preview zoom, separate from the template's font/style settings.
  final double watermarkZoom;
}
