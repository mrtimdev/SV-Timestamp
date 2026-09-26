import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sv_timestamp/core/watermark/watermark_contrast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'contrast changes between dark and bright scenes without flickering',
    () {
      final dark = WatermarkContrast.fromBrightness(.1);
      final bright = WatermarkContrast.fromBrightness(.9);
      expect(dark.shadowColor.r, 1);
      expect(bright.shadowColor.r, 0);
      expect(
        WatermarkContrast.fromBrightness(.48, previous: dark).darkScene,
        isTrue,
      );
      expect(
        WatermarkContrast.fromBrightness(.42, previous: bright).darkScene,
        isFalse,
      );
      expect(
        WatermarkContrast.fromBrightness(.6, previous: dark).darkScene,
        isFalse,
      );
      expect(
        WatermarkContrast.fromBrightness(.2, previous: bright).darkScene,
        isTrue,
      );
    },
  );

  test(
    'camera sampler respects BGRA channels, pixel stride and padded rows',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      // Two red pixels per row; padding must not contribute to brightness.
      final bytes = Uint8List.fromList([
        0,
        0,
        255,
        255,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        255,
        0,
        0,
        255,
        255,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        255,
      ]);
      // ignore: deprecated_member_use
      final image = CameraImage.fromPlatformData({
        'width': 2,
        'height': 2,
        'format': 1111970369,
        'planes': [
          {'bytes': bytes, 'bytesPerRow': 12},
        ],
      });
      expect(WatermarkContrast.cameraBrightness(image), closeTo(.2126, .0001));
    },
  );

  test('YUV sampler uses only luma and ignores cropped-out pixels', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // ignore: deprecated_member_use
    final image = CameraImage.fromPlatformData({
      'width': 4,
      'height': 2,
      'format': 35,
      'planes': [
        {
          'bytes': Uint8List.fromList([0, 0, 255, 255, 73, 0, 0, 255, 255, 73]),
          'bytesPerRow': 5,
          'bytesPerPixel': 1,
        },
      ],
    });
    expect(WatermarkContrast.cameraBrightness(image), closeTo(.5, .0001));
    expect(
      WatermarkContrast.cameraBrightness(
        image,
        region: const Rect.fromLTWH(0, 0, 2, 2),
      ),
      0,
    );
    expect(
      WatermarkContrast.cameraBrightness(
        image,
        region: const Rect.fromLTWH(2, 0, 2, 2),
      ),
      1,
    );
  });

  test('photo sampling chooses contrast from the visible crop', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.black, BlendMode.src);
    canvas.drawRect(
      const Rect.fromLTWH(10, 0, 10, 20),
      Paint()..color = Colors.white,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(20, 20);
    addTearDown(image.dispose);
    addTearDown(picture.dispose);
    expect(
      (await WatermarkContrast.fromImage(
        image,
        region: const Rect.fromLTWH(0, 0, 10, 20),
      )).darkScene,
      isTrue,
    );
    expect(
      (await WatermarkContrast.fromImage(
        image,
        region: const Rect.fromLTWH(10, 0, 10, 20),
      )).darkScene,
      isFalse,
    );
  });
}
