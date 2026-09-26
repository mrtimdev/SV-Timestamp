import 'dart:ui';

import '../../../models/watermark_position.dart';
import 'camera_preview_layout.dart';

class MappedWatermark {
  const MappedWatermark({
    required this.rect,
    required this.scale,
    required this.sourceRect,
  });
  final Rect rect;
  final double scale;
  final Rect sourceRect;
}

abstract final class ImageCoordinateMapper {
  static MappedWatermark map({
    required WatermarkCaptureLayout layout,
    required Size imageSize,
    Size? renderedWatermarkSize,
  }) {
    final oriented = _orientedLayout(layout);
    final source = CameraPreviewLayout.coverSourceRect(
      imageSize,
      oriented.previewSize,
    );
    final scale = source.width / oriented.previewSize.width;
    final imageWatermarkSize =
        renderedWatermarkSize ??
        Size(
          oriented.watermarkSize.width * scale,
          oriented.watermarkSize.height * scale,
        );
    final imageMargin = oriented.margin * scale;
    final safeRect = Rect.fromLTWH(
      source.left + oriented.safeRect.left * scale,
      source.top + oriented.safeRect.top * scale,
      oriented.safeRect.width * scale,
      oriented.safeRect.height * scale,
    );
    // The watermark belongs to the screen, not the mirrored camera texture.
    // Front and rear cameras must use the same visible frame coordinates.
    final local = oriented.position.resolve(
      safeRect.size,
      imageWatermarkSize,
      margin: imageMargin,
    );
    return MappedWatermark(
      rect: Rect.fromLTWH(
        safeRect.left + local.dx,
        safeRect.top + local.dy,
        imageWatermarkSize.width,
        imageWatermarkSize.height,
      ),
      scale: scale,
      sourceRect: source,
    );
  }

  static WatermarkCaptureLayout _orientedLayout(WatermarkCaptureLayout layout) {
    final turns = layout.quarterTurns % 4;
    if (turns == 0) return layout;
    final size = layout.previewSize;
    final rect = layout.safeRect;
    final rotatedSize = turns.isOdd ? Size(size.height, size.width) : size;
    // Undo the preview widget's clockwise rotation to obtain upright photo
    // coordinates. The normalized position is already in those coordinates.
    final rotatedRect = switch (turns) {
      1 => Rect.fromLTWH(
        rect.top,
        size.width - rect.right,
        rect.height,
        rect.width,
      ),
      2 => Rect.fromLTWH(
        size.width - rect.right,
        size.height - rect.bottom,
        rect.width,
        rect.height,
      ),
      3 => Rect.fromLTWH(
        size.height - rect.bottom,
        rect.left,
        rect.height,
        rect.width,
      ),
      _ => rect,
    };
    return WatermarkCaptureLayout(
      previewSize: rotatedSize,
      safeRect: rotatedRect,
      watermarkSize: turns.isOdd
          ? Size(layout.watermarkSize.height, layout.watermarkSize.width)
          : layout.watermarkSize,
      position: layout.position,
      margin: layout.margin,
      mirrored: layout.mirrored,
      quarterTurns: 0,
      watermarkZoom: layout.watermarkZoom,
    );
  }
}
