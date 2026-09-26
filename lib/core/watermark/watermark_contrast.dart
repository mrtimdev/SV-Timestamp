import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Scene-adaptive halo shared by the live overlay and photo renderer.
class WatermarkContrast {
  const WatermarkContrast({this.darkScene = false});

  final bool darkScene;

  factory WatermarkContrast.fromBrightness(
    double brightness, {
    WatermarkContrast? previous,
  }) {
    // Hysteresis prevents flickering when exposure hovers near the threshold.
    final threshold = previous == null ? .45 : (previous.darkScene ? .52 : .38);
    return WatermarkContrast(darkScene: brightness < threshold);
  }

  Color get shadowColor => darkScene
      ? Colors.white.withValues(alpha: .35)
      : Colors.black.withValues(alpha: .85);

  List<Shadow> textShadows(double scale) => [
    Shadow(color: shadowColor, blurRadius: 3 * scale),
    // Keep a dark edge even over mixed light/dark detail in the same frame.
    Shadow(
      color: Colors.black.withValues(alpha: .8),
      blurRadius: scale,
      offset: Offset(0, .5 * scale),
    ),
  ];

  List<BoxShadow> boxShadows(double scale) => [
    BoxShadow(color: shadowColor, blurRadius: 3 * scale),
  ];

  void paintBoxShadow(Canvas canvas, RRect rect, double scale) {
    for (final shadow in boxShadows(scale)) {
      canvas.drawRRect(rect.shift(shadow.offset), shadow.toPaint());
    }
  }

  /// A small regular grid avoids decoding or copying every camera pixel.
  static double? cameraBrightness(CameraImage image, {Rect? region}) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final bgra = image.format.group == ImageFormatGroup.bgra8888;
    if (!bgra &&
        image.format.group != ImageFormatGroup.yuv420 &&
        image.format.group != ImageFormatGroup.nv21) {
      return null;
    }
    final stride = plane.bytesPerPixel ?? (bgra ? 4 : 1);
    return sampleBrightness(image.width, image.height, (x, y) {
      final index = y * plane.bytesPerRow + x * stride;
      if (index < 0 || index + (bgra ? 2 : 0) >= plane.bytes.length) {
        return null;
      }
      if (!bgra) return plane.bytes[index] / 255;
      return (.2126 * plane.bytes[index + 2] +
              .7152 * plane.bytes[index + 1] +
              .0722 * plane.bytes[index]) /
          255;
    }, region: region);
  }

  static double? sampleBrightness(
    int width,
    int height,
    double? Function(int x, int y) pixel, {
    Rect? region,
  }) {
    final bounds = Offset.zero & Size(width.toDouble(), height.toDouble());
    final rect = region?.intersect(bounds) ?? bounds;
    if (rect.isEmpty) return null;
    var total = 0.0;
    var count = 0;
    for (var row = 0; row < 12; row++) {
      for (var column = 0; column < 12; column++) {
        final x = (rect.left + rect.width * (column + .5) / 12).floor();
        final y = (rect.top + rect.height * (row + .5) / 12).floor();
        final value = pixel(x, y);
        if (value == null) continue;
        total += value;
        count++;
      }
    }
    return count == 0 ? null : total / count;
  }

  static Future<WatermarkContrast> fromImage(
    ui.Image image, {
    Rect? region,
  }) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return const WatermarkContrast();
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final brightness = sampleBrightness(image.width, image.height, (x, y) {
      final index = (y * image.width + x) * 4;
      return (.2126 * bytes[index] +
              .7152 * bytes[index + 1] +
              .0722 * bytes[index + 2]) /
          255;
    }, region: region);
    return WatermarkContrast.fromBrightness(brightness ?? 1);
  }
}
