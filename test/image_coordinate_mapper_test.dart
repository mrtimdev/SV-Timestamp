import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sv_timestamp/features/camera/layout/camera_preview_layout.dart';
import 'package:sv_timestamp/features/camera/layout/image_coordinate_mapper.dart';
import 'package:sv_timestamp/models/watermark_position.dart';

void main() {
  const preview = Size(400, 800);
  const safe = Rect.fromLTRB(12, 80, 388, 650);
  const watermark = Size(180, 140);

  WatermarkCaptureLayout layout({
    WatermarkPosition position = const WatermarkPosition(),
    bool mirrored = false,
    Size previewSize = preview,
    Rect safeRect = safe,
    int quarterTurns = 0,
  }) => WatermarkCaptureLayout(
    previewSize: previewSize,
    safeRect: safeRect,
    watermarkSize: watermark,
    position: position,
    margin: 12,
    mirrored: mirrored,
    quarterTurns: quarterTurns,
  );

  test('normalization restores all edge positions without clipping', () {
    for (final position in const [
      WatermarkPosition(x: 0, y: 0),
      WatermarkPosition(x: 1, y: 0),
      WatermarkPosition(x: 0, y: 1),
      WatermarkPosition(x: 1, y: 1),
      WatermarkPosition(x: .37, y: .62),
    ]) {
      final offset = position.resolve(safe.size, watermark, margin: 12);
      final restored = WatermarkPosition.fromOffset(
        offset,
        safe.size,
        watermark,
        margin: 12,
      );
      expect(restored.x, closeTo(position.x, .0001));
      expect(restored.y, closeTo(position.y, .0001));
      expect(offset.dx, greaterThanOrEqualTo(12));
      expect(offset.dy, greaterThanOrEqualTo(12));
      expect(offset.dx + watermark.width, lessThanOrEqualTo(safe.width - 12));
      expect(offset.dy + watermark.height, lessThanOrEqualTo(safe.height - 12));
    }
  });

  test('portrait cover crop maps preview into full-resolution image', () {
    final mapped = ImageCoordinateMapper.map(
      layout: layout(position: const WatermarkPosition(x: 0, y: 0)),
      imageSize: const Size(3000, 4000),
    );
    final source = CameraPreviewLayout.coverSourceRect(
      const Size(3000, 4000),
      preview,
    );
    expect(source.width / source.height, closeTo(.5, .001));
    expect(mapped.rect.left, greaterThan(source.left));
    expect(mapped.rect.top, greaterThan(source.top));
  });

  test('landscape-left and landscape-right preserve normalized position', () {
    const image = Size(4000, 3000);
    for (final turn in const [1, 3]) {
      final mapped = ImageCoordinateMapper.map(
        layout: layout(
          position: const WatermarkPosition(x: .25, y: .75),
          quarterTurns: turn,
        ),
        imageSize: image,
      );
      expect(mapped.rect.left, greaterThanOrEqualTo(0));
      expect(mapped.rect.top, greaterThanOrEqualTo(0));
      expect(mapped.rect.right, lessThanOrEqualTo(image.width));
      expect(mapped.rect.bottom, lessThanOrEqualTo(image.height));
    }
  });

  test('front camera preserves screen placement in every orientation', () {
    for (final turns in [0, 1, 2, 3]) {
      final image = turns.isOdd
          ? const Size(4000, 2000)
          : const Size(2000, 4000);
      final orientedSafe = switch (turns) {
        1 => const Rect.fromLTRB(80, 12, 650, 388),
        2 => const Rect.fromLTRB(12, 150, 388, 720),
        3 => const Rect.fromLTRB(150, 12, 720, 388),
        _ => safe,
      };
      final orientedMark = turns.isOdd ? const Size(140, 180) : watermark;
      for (final position in const [
        WatermarkPosition(x: 0, y: 1),
        WatermarkPosition(x: 1, y: 0),
        WatermarkPosition(x: .2, y: .7),
      ]) {
        final expected = Rect.fromLTWH(
          (orientedSafe.left +
                  12 +
                  (orientedSafe.width - orientedMark.width - 24) * position.x) *
              5,
          (orientedSafe.top +
                  12 +
                  (orientedSafe.height - orientedMark.height - 24) *
                      position.y) *
              5,
          orientedMark.width * 5,
          orientedMark.height * 5,
        );
        for (final mirrored in [false, true]) {
          final mapped = ImageCoordinateMapper.map(
            layout: layout(
              position: position,
              quarterTurns: turns,
              mirrored: mirrored,
            ),
            imageSize: image,
          );
          expect(mapped.rect.left, closeTo(expected.left, .0001));
          expect(mapped.rect.top, closeTo(expected.top, .0001));
          expect(mapped.rect.width, closeTo(expected.width, .0001));
          expect(mapped.rect.height, closeTo(expected.height, .0001));
        }
      }
    }
  });

  test('bottom anchor uses actual exported text height within safe area', () {
    final mapped = ImageCoordinateMapper.map(
      layout: layout(),
      imageSize: const Size(2000, 4000),
      renderedWatermarkSize: const Size(900, 1000),
    );
    expect(mapped.rect.left, (safe.left + 12) * 5);
    expect(mapped.rect.bottom, (safe.bottom - 12) * 5);
    expect(mapped.rect.height, 1000);
  });
}
