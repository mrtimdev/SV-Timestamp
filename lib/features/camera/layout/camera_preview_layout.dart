import 'dart:math' as math;
import 'dart:ui';

abstract final class CameraPreviewLayout {
  static Rect coverSourceRect(Size image, Size preview) {
    if (image.isEmpty || preview.isEmpty) return Offset.zero & image;
    final scale = math.max(
      preview.width / image.width,
      preview.height / image.height,
    );
    final visible = Size(preview.width / scale, preview.height / scale);
    return Rect.fromLTWH(
      (image.width - visible.width) / 2,
      (image.height - visible.height) / 2,
      visible.width,
      visible.height,
    );
  }

  static Rect safePhotoRect({
    required Size preview,
    required double topControlsBottom,
    required double bottomControlsTop,
    double horizontalMargin = 12,
  }) {
    final top = topControlsBottom.clamp(0.0, preview.height);
    final bottom = bottomControlsTop.clamp(top, preview.height);
    return Rect.fromLTRB(
      horizontalMargin,
      top,
      preview.width - horizontalMargin,
      bottom,
    );
  }
}
