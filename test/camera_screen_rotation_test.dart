import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sv_timestamp/features/camera/providers/camera_provider.dart';
import 'package:sv_timestamp/features/camera/screens/camera_screen.dart';
import 'package:sv_timestamp/features/camera/widgets/draggable_watermark_overlay.dart';
import 'package:sv_timestamp/features/camera/widgets/timestamp_overlay.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';
import 'package:sv_timestamp/models/app_settings.dart';
import 'package:sv_timestamp/models/location_stamp.dart';

class _Camera extends CameraProvider {
  _Camera(super.settingsProvider) {
    controller = CameraController(
      const CameraDescription(
        name: 'front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      ),
      ResolutionPreset.low,
      enableAudio: false,
    );
    location = const LocationStamp(
      latitude: 11.5362,
      longitude: 104.9031,
      accuracy: 5,
      city: 'Phnom Penh',
      country: 'Cambodia',
    );
  }

  double zoom = 1;
  @override
  double get minZoom => .5;
  @override
  double get maxZoom => 3;
  @override
  double get currentZoom => zoom;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> setZoom(double value) async {
    zoom = value;
    notifyListeners();
  }

  void rotate(DeviceOrientation value) {
    deviceOrientation = value;
    notifyListeners();
  }
}

void main() {
  testWidgets('drag reaches every photo edge after ratio and margin changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider()
      ..settings = const AppSettings(
        language: AppLanguage.english,
        watermarkZoom: .4,
        normalizedX: .5,
        normalizedY: .5,
      );
    final camera = _Camera(settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<CameraProvider>.value(value: camera),
        ],
        child: const MaterialApp(home: CameraScreen()),
      ),
    );
    for (final margin in [4.0, 28.0]) {
      for (final ratio in [...CameraRatio.values, CameraRatio.ratio3x4]) {
        await settings.update(
          settings.settings.copyWith(
            cameraRatio: ratio,
            watermarkMargin: margin,
            normalizedX: .5,
            normalizedY: .5,
          ),
        );
        await tester.pumpAndSettle();
        final area = tester.getRect(find.byType(DraggableWatermarkOverlay));
        final expectedSize = ratio == CameraRatio.full
            ? const Size(390, 844)
            : Size(390, 390 * ratio.h / ratio.w);
        expect(area.width, closeTo(expectedSize.width, .0001));
        expect(area.height, closeTo(expectedSize.height, .0001));
        expect(
          camera.captureLayout!.previewSize.width,
          closeTo(area.width, .0001),
        );
        expect(
          camera.captureLayout!.previewSize.height,
          closeTo(area.height, .0001),
        );
        expect(camera.captureLayout!.safeRect.topLeft, Offset.zero);
        expect(
          camera.captureLayout!.safeRect.width,
          closeTo(area.width, .0001),
        );
        expect(
          camera.captureLayout!.safeRect.height,
          closeTo(area.height, .0001),
        );
        final mark = find.byType(TimestampOverlay);
        final gesture = await tester.startGesture(tester.getCenter(mark));
        await gesture.moveBy(const Offset(25, 25));
        await tester.pump();
        for (final target in const [
          Offset(-2000, -2000),
          Offset(2000, -2000),
          Offset(2000, 2000),
          Offset(-2000, 2000),
        ]) {
          await gesture.moveTo(target);
          await tester.pump();
          final rect = tester.getRect(mark);
          expect(
            target.dx < 0 ? rect.left : rect.right,
            closeTo(
              target.dx < 0 ? area.left + margin : area.right - margin,
              .01,
            ),
          );
          expect(
            target.dy < 0 ? rect.top : rect.bottom,
            closeTo(
              target.dy < 0 ? area.top + margin : area.bottom - margin,
              .01,
            ),
          );
          expect(
            camera.captureLayout!.watermarkSize.width,
            closeTo(rect.width, .01),
          );
          expect(
            camera.captureLayout!.watermarkSize.height,
            closeTo(rect.height, .01),
          );
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(settings.settings.normalizedX, closeTo(0, .0001));
        expect(settings.settings.normalizedY, closeTo(1, .0001));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    camera.dispose();
    settings.dispose();
  });

  for (final screen in [const Size(390, 844), const Size(320, 568)]) {
    for (final ratio in CameraRatio.values) {
      testWidgets(
        'controls and bottom-left watermark rotate with ${ratio.name} on $screen',
        (tester) async {
          tester.view.physicalSize = screen;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final settings = SettingsProvider()
            ..settings = AppSettings(
              cameraRatio: ratio,
              language: AppLanguage.english,
              normalizedX: .7,
              normalizedY: .3,
            );
          final camera = _Camera(settings);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider<CameraProvider>.value(value: camera),
              ],
              child: const MaterialApp(home: CameraScreen()),
            ),
          );

          double landscapeX = 0, landscapeY = 1;
          for (final orientation in [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.portraitUp,
          ]) {
            camera.rotate(orientation);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final status = tester.getRect(
              find.byKey(const ValueKey('gps-status-badge')),
            );
            expect(status.height, lessThan(80));
            final ratios = CameraRatio.values
                .map((r) => tester.getRect(find.text(r.label)))
                .toList();
            final dock = tester.getRect(
              find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_CaptureDock',
              ),
            );
            for (final rect in ratios) {
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(screen.width));
              expect(rect.bottom, lessThanOrEqualTo(screen.height));
              expect(rect.overlaps(status), isFalse);
              expect(rect.overlaps(dock), isFalse);
            }
            final areaFinder = find.byType(DraggableWatermarkOverlay);
            final overlay = tester.widget<DraggableWatermarkOverlay>(
              areaFinder,
            );
            final area = tester.getRect(areaFinder);
            final stamp = tester.getRect(find.byType(TimestampOverlay));
            expect(stamp.left, greaterThanOrEqualTo(area.left));
            expect(stamp.top, greaterThanOrEqualTo(area.top));
            expect(stamp.right, lessThanOrEqualTo(area.right));
            expect(stamp.bottom, lessThanOrEqualTo(area.bottom));
            expect(overlay.draggable, isTrue);
            final landscape =
                orientation == DeviceOrientation.landscapeLeft ||
                orientation == DeviceOrientation.landscapeRight;
            if (landscape) {
              final left = orientation == DeviceOrientation.landscapeLeft;
              expect(
                overlay.position.x,
                closeTo(left ? 1 - landscapeY : landscapeY, .0001),
              );
              expect(
                overlay.position.y,
                closeTo(left ? landscapeX : 1 - landscapeX, .0001),
              );
              final delta = left
                  ? const Offset(30, 25)
                  : const Offset(-30, -25);
              await tester.drag(find.byType(TimestampOverlay), delta);
              await tester.pumpAndSettle();
              final moved = tester.getRect(find.byType(TimestampOverlay));
              expect((moved.topLeft - stamp.topLeft).distance, greaterThan(10));
              final capture = camera.captureLayout!;
              expect(capture.mirrored, isTrue);
              expect(capture.quarterTurns, left ? 1 : 3);
              landscapeX = capture.position.x;
              landscapeY = capture.position.y;
              // Clock ticks and camera rebuilds must not snap a dragged stamp back.
              await tester.pump(const Duration(seconds: 2));
              await tester.pumpAndSettle();
              expect(tester.getRect(find.byType(TimestampOverlay)), moved);
            } else {
              expect(overlay.position.x, .7);
              expect(overlay.position.y, .3);
            }
          }
          if (screen.width == 390 && ratio == CameraRatio.ratio3x4) {
            final markFinder = find.byType(TimestampOverlay);
            final beforePinch = tester.getRect(markFinder);
            final cameraZoom = camera.currentZoom;
            final center = beforePinch.center;
            final first = await tester.startGesture(
              center - const Offset(30, 0),
              pointer: 31,
            );
            final second = await tester.startGesture(
              center + const Offset(30, 0),
              pointer: 32,
            );
            for (final distance in [26.0, 22.0, 18.0]) {
              await first.moveTo(center - Offset(distance, 0));
              await second.moveTo(center + Offset(distance, 0));
              await tester.pump();
            }
            final duringPinch = tester.getRect(markFinder);
            expect(duringPinch.width, closeTo(beforePinch.width * .6, 1));
            expect(
              camera.captureLayout!.watermarkSize.width,
              closeTo(duringPinch.width, .01),
            );
            expect(
              settings.settings.watermarkZoom,
              1,
            ); // Saved only at gesture end.
            await first.up();
            await second.up();
            await tester.pumpAndSettle();
            expect(settings.settings.watermarkZoom, closeTo(.6, .01));
            expect(camera.currentZoom, cameraZoom);
            expect(
              tester.getRect(markFinder).width,
              closeTo(duringPinch.width, .01),
            );
            final reloaded = SettingsProvider();
            await reloaded.load();
            expect(reloaded.settings.watermarkZoom, closeTo(.6, .01));
            reloaded.dispose();
            await tester.tap(find.byKey(const ValueKey('edit-camera-note')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('camera-note-field')),
              'Inspection complete',
            );
            await tester.tap(find.byKey(const ValueKey('save-camera-note')));
            await tester.pumpAndSettle();
            expect(settings.settings.customNote, 'Inspection complete');
            expect(settings.settings.showNote, isTrue);
            expect(
              tester
                  .widget<TimestampOverlay>(find.byType(TimestampOverlay))
                  .settings
                  .customNote,
              'Inspection complete',
            );
            final saved = await SharedPreferences.getInstance();
            expect(saved.getString('customNote'), 'Inspection complete');
            await tester.tap(find.byKey(const ValueKey('edit-camera-note')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('camera-note-field')),
              'Discard this',
            );
            await tester.tap(find.text('Cancel'));
            await tester.pumpAndSettle();
            expect(settings.settings.customNote, 'Inspection complete');
          }
          await tester.tap(find.text('1:1'));
          await tester.pumpAndSettle();
          expect(settings.settings.cameraRatio, CameraRatio.ratio1x1);
          await tester.pumpWidget(const SizedBox.shrink());
          camera.dispose();
          settings.dispose();
        },
      );
    }
  }
}
