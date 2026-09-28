import 'package:flutter/services.dart';

/// Physical rotation independent of Android's portrait-locked activity.
abstract final class DeviceOrientationService {
  static const _channel = EventChannel(
    'com.svtrucking.timestamp/device_orientation',
  );

  static Stream<DeviceOrientation> get orientations => _channel
      .receiveBroadcastStream()
      .map((event) => fromDegrees(event as int))
      .where((orientation) => orientation != null)
      .cast<DeviceOrientation>()
      .distinct();

  static DeviceOrientation? fromDegrees(int degrees) {
    if (degrees < 0 || degrees >= 360) return null;
    // Ignore diagonal positions to avoid flickering around a 45-degree boundary.
    if (degrees <= 30 || degrees >= 330) return DeviceOrientation.portraitUp;
    if (degrees >= 60 && degrees <= 120) {
      return DeviceOrientation.landscapeRight;
    }
    if (degrees >= 150 && degrees <= 210) return DeviceOrientation.portraitDown;
    if (degrees >= 240 && degrees <= 300) {
      return DeviceOrientation.landscapeLeft;
    }
    return null;
  }
}
