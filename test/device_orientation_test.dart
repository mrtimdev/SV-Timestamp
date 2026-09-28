import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sv_timestamp/core/services/device_orientation_service.dart';
import 'package:sv_timestamp/features/camera/providers/camera_provider.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('physical sensor angles distinguish both landscape directions', () {
    expect(
      DeviceOrientationService.fromDegrees(0),
      DeviceOrientation.portraitUp,
    );
    expect(
      DeviceOrientationService.fromDegrees(359),
      DeviceOrientation.portraitUp,
    );
    expect(
      DeviceOrientationService.fromDegrees(90),
      DeviceOrientation.landscapeRight,
    );
    expect(
      DeviceOrientationService.fromDegrees(180),
      DeviceOrientation.portraitDown,
    );
    expect(
      DeviceOrientationService.fromDegrees(270),
      DeviceOrientation.landscapeLeft,
    );
    for (final degrees in [-1, 45, 135, 225, 315, 360]) {
      expect(DeviceOrientationService.fromDegrees(degrees), isNull);
    }
  });

  test(
    'sensor events rotate the provider while display orientation stays portrait',
    () async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      const name = 'com.svtrucking.timestamp/device_orientation';
      const codec = StandardMethodCodec();
      final calls = <String>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(name),
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel(name),
          null,
        ),
      );
      final settings = SettingsProvider();
      final camera = CameraProvider(
        settings,
        orientationStream: DeviceOrientationService.orientations,
      );
      var changes = 0;
      camera.addListener(() => changes++);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen']);

      Future<void> send(int degrees) async {
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          name,
          codec.encodeSuccessEnvelope(degrees),
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);
      }

      await send(270);
      expect(camera.deviceOrientation, DeviceOrientation.landscapeLeft);
      await send(280);
      await send(315);
      await send(-1);
      expect(changes, 1); // Repeated, diagonal and flat readings do not jitter.
      await send(
        90,
      ); // Direct left-to-right rotation must not require portrait first.
      expect(camera.deviceOrientation, DeviceOrientation.landscapeRight);
      await send(0);
      expect(camera.deviceOrientation, DeviceOrientation.portraitUp);
      expect(changes, 3);
      camera.dispose();
      settings.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen', 'cancel']);
    },
  );
}
