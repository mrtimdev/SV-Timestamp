import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sv_timestamp/core/services/image_stamp_service.dart';
import 'package:sv_timestamp/core/watermark/field_report_watermark.dart';
import 'package:sv_timestamp/core/watermark/watermark_contrast.dart';
import 'package:sv_timestamp/models/app_settings.dart';
import 'package:sv_timestamp/models/location_stamp.dart';
import 'package:sv_timestamp/models/watermark_position.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final time = DateTime(2026, 9, 26, 9, 29);
  const location = LocationStamp(
    latitude: 11.5362,
    longitude: 104.9031,
    city: 'Phnom Penh',
    country: 'Cambodia',
  );

  test(
    'reference template formats live time, date, weekday and custom note',
    () {
      final layout = FieldReportWatermark(
        settings: const AppSettings(
          showGps: true,
          customNote: 'Gate 3 inspection',
        ),
        location: location,
        device: 'iPhone 12 Pro Max',
        time: time,
        width: 320,
      );
      expect(layout.semanticsLabel, contains('09:29'));
      expect(layout.semanticsLabel, isNot(contains('AM')));
      expect(layout.semanticsLabel, contains('26 Sep 2026 Sat'));
      expect(layout.semanticsLabel, contains('11.5362'));
      expect(layout.semanticsLabel, contains('Gate 3 inspection'));
      expect(layout.logoRect!.bottom, lessThan(layout.divider!.top));
    },
  );

  test('hidden fields stay absent in the shared design', () {
    final layout = FieldReportWatermark(
      settings: const AppSettings(
        showDate: false,
        showTime: false,
        showNote: false,
        showLogo: false,
        showDevice: false,
        showAddress: false,
        showGps: false,
      ),
      location: location,
      device: 'iPhone',
      time: time,
      width: 320,
    );
    expect(layout.semanticsLabel, isEmpty);
    expect(layout.logoRect, isNull);
    expect(layout.divider, isNull);
  });

  test(
    'row spacing applies between visible items without changing the header',
    () {
      FieldReportWatermark layout(double spacing) => FieldReportWatermark(
        settings: AppSettings(watermarkRowSpacing: spacing),
        location: location,
        device: 'Test phone',
        time: time,
        width: 320,
      );
      final compact = layout(0);
      final spaced = layout(12);
      addTearDown(compact.dispose);
      addTearDown(spaced.dispose);
      // The default address, device and note produce two gaps; GPS stays hidden.
      expect(spaced.semanticsLabel, isNot(contains('Lat:')));
      expect(spaced.size.height - compact.size.height, 24);
      expect(spaced.divider, compact.divider);
      expect(spaced.logoRect, compact.logoRect);
    },
  );

  for (final zoom in [1.0, .5, 1.1]) {
    test('photo export matches the shared live layout at zoom $zoom', () async {
      final directory = await Directory.systemTemp.createTemp(
        'field_report_export_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/source.png');
      await source.writeAsBytes(
        img.encodePng(img.Image(width: 960, height: 1440)),
      );
      final destination = '${directory.path}/result.jpg';
      const settings = AppSettings(
        showLogo: false,
        showGps: true,
        watermarkRowSpacing: 11,
        language: AppLanguage.english,
        customNote: 'Gate 3 inspection',
      );
      final design = FieldReportWatermark(
        settings: settings,
        location: location,
        device: 'Test phone',
        time: time,
        width: 240 * zoom,
        contrast: const WatermarkContrast(darkScene: true),
      );
      final layout = WatermarkCaptureLayout(
        previewSize: const Size(320, 480),
        safeRect: const Rect.fromLTRB(12, 12, 308, 468),
        watermarkSize: design.size,
        watermarkZoom: zoom,
        position: const WatermarkPosition(x: .2, y: .6),
        margin: 12,
        mirrored: true,
        quarterTurns: 0,
      );
      await ImageStampService().stamp(
        source: source.path,
        destination: destination,
        time: time,
        settings: settings,
        location: location,
        device: 'Test phone',
        layout: layout,
      );

      // Draw the same live design at its expected 3x screen coordinates. This
      // catches extra padding, mirroring or export-only layout changes.
      final x = (24 + (296 - design.size.width - 24) * .2) * 3;
      final y = (24 + (456 - design.size.height - 24) * .6) * 3;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawColor(Colors.black, BlendMode.src);
      canvas.translate(x, y);
      canvas.scale(3);
      design.paint(canvas);
      final picture = recorder.endRecording();
      final expected = await picture.toImage(960, 1440);
      final rgba = (await expected.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final image = img.Image.fromBytes(
        width: 960,
        height: 1440,
        bytes: rgba.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      expect(
        await File(destination).readAsBytes(),
        img.encodeJpg(image, quality: 94),
      );
      expected.dispose();
      picture.dispose();
      design.dispose();
    });
  }
}
