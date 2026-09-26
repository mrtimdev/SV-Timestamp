import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sv_timestamp/features/camera/widgets/draggable_watermark_overlay.dart';
import 'package:sv_timestamp/models/watermark_position.dart';

void main() {
  for (final turns in [0, 1, 3]) {
    testWidgets(
      'pinch scales uniformly around its focal point at rotation $turns',
      (tester) async {
        var saved = const WatermarkTransform(
          position: WatermarkPosition(x: .5, y: .5),
          scale: 1,
        );
        var commits = 0;
        Size? reportedSize;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 400,
                height: 500,
                child: StatefulBuilder(
                  builder: (context, setState) => DraggableWatermarkOverlay(
                    position: saved.position,
                    scale: saved.scale,
                    margin: 12,
                    quarterTurns: turns,
                    onChanged: (value) => setState(() {
                      saved = value;
                      commits++;
                    }),
                    onLayout: (size, transform) => reportedSize = size,
                    child: Container(
                      key: const ValueKey('mark'),
                      width: 200,
                      height: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final finder = find.byKey(const ValueKey('mark'));
        final initial = tester.getRect(finder);
        final center = initial.center;
        final first = await tester.startGesture(
          center - const Offset(40, 0),
          pointer: 1,
        );
        final second = await tester.startGesture(
          center + const Offset(40, 0),
          pointer: 2,
        );
        await tester.pump();
        var lastWidth = initial.width;
        for (final distance in [36.0, 32.0, 28.0, 24.0, 20.0]) {
          await first.moveTo(center - Offset(distance, 0));
          await second.moveTo(center + Offset(distance, 0));
          await tester.pump();
          final rect = tester.getRect(finder);
          expect(rect.width, lessThanOrEqualTo(lastWidth + .01));
          expect(
            rect.width / rect.height,
            closeTo(initial.width / initial.height, .0001),
          );
          expect((rect.center - center).distance, lessThan(1));
          lastWidth = rect.width;
          expect(commits, 0);
        }
        final small = tester.getRect(finder);
        expect(small.width, closeTo(initial.width * .5, 1));
        expect(reportedSize!.width, closeTo(small.width, .01));
        // A finger leaving the pinch must not commit or move the content.
        await second.up();
        await tester.pump();
        expect(commits, 0);
        expect(tester.getRect(finder), small);
        await first.moveBy(const Offset(20, 15));
        await tester.pump();
        await first.moveBy(const Offset(10, 10));
        await tester.pump();
        expect(tester.getRect(finder).width, closeTo(small.width, .01));
        expect(
          (tester.getRect(finder).center - small.center).distance,
          greaterThan(10),
        );
        await first.up();
        await tester.pumpAndSettle();
        expect(commits, 1);
        expect(saved.scale, closeTo(.5, .01));
        final settled = tester.getRect(finder);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.getRect(finder), settled);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pinch grows back smoothly and is bounded by the photo margins', (
    tester,
  ) async {
    var saved = const WatermarkTransform(
      position: WatermarkPosition(x: 0, y: 1),
      scale: .5,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setState) => DraggableWatermarkOverlay(
                position: saved.position,
                scale: saved.scale,
                margin: 12,
                quarterTurns: 0,
                onChanged: (value) => setState(() => saved = value),
                onLayout: (_, _) {},
                child: Container(
                  key: const ValueKey('mark'),
                  width: 200,
                  height: 120,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mark = find.byKey(const ValueKey('mark'));
    final area = tester.getRect(find.byType(DraggableWatermarkOverlay));
    final center = tester.getCenter(mark);
    final first = await tester.startGesture(
      center - const Offset(20, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    for (final distance in [25.0, 35.0, 50.0, 70.0, 90.0]) {
      await first.moveTo(center - Offset(distance, 0));
      await second.moveTo(center + Offset(distance, 0));
      await tester.pump();
      final rect = tester.getRect(mark);
      expect(rect.left, greaterThanOrEqualTo(area.left + 12 - .01));
      expect(rect.top, greaterThanOrEqualTo(area.top + 12 - .01));
      expect(rect.right, lessThanOrEqualTo(area.right - 12 + .01));
      expect(rect.bottom, lessThanOrEqualTo(area.bottom - 12 + .01));
    }
    expect(tester.getRect(mark).width, closeTo(276, .01));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(saved.scale, closeTo(276 / 200, .01));
  });
}
