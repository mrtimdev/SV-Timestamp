import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sv_timestamp/features/camera/widgets/oriented_camera_preview.dart';

class _PreviewController extends CameraController {
  _PreviewController(CameraLensDirection lens)
    : super(
        CameraDescription(
          name: 'test',
          lensDirection: lens,
          sensorOrientation: 90,
        ),
        ResolutionPreset.low,
      ) {
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1280, 720),
    );
  }

  @override
  Widget buildPreview() =>
      const ColoredBox(key: ValueKey('native-preview'), color: Colors.blue);
}

void main() {
  for (final lens in [CameraLensDirection.back, CameraLensDirection.front]) {
    testWidgets(
      'Android $lens texture keeps its frame during physical rotation and capture',
      (tester) async {
        final controller = _PreviewController(lens);
        addTearDown(controller.dispose);
        for (final turns in [0, 1, 3, 2, 0]) {
          // A photo lock must not rotate the live texture inside the portrait UI.
          for (final lock in [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]) {
            controller.value = controller.value.copyWith(
              lockedCaptureOrientation: Optional.of(lock),
            );
            await tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: SizedBox(
                    width: 300,
                    height: 400,
                    child: OrientedCameraPreview(
                      controller: controller,
                      quarterTurns: turns,
                    ),
                  ),
                ),
              ),
            );
            expect(
              tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
              0,
            );
            final texture = tester.getRect(
              find.byKey(const ValueKey('native-preview')),
            );
            expect(texture.width, closeTo(300, .001));
            expect(texture.height, closeTo(300 * 1280 / 720, .001));
            expect(tester.takeException(), isNull);
          }
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
