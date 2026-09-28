import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sv_timestamp/core/services/image_stamp_service.dart';
import 'package:sv_timestamp/models/app_settings.dart';
import 'package:sv_timestamp/models/location_stamp.dart';
import 'package:sv_timestamp/models/watermark_position.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default logo has a transparent background', () {
    final logo = img.decodePng(
      File('assets/images/watermark_sv_app_icon.png').readAsBytesSync(),
    )!;
    expect(logo.getPixel(0, 0).a, 0);
    expect(logo.getPixel(logo.width - 1, logo.height - 1).a, 0);
  });

  for (final template in [
    WatermarkTemplate.classic,
    WatermarkTemplate.fieldReport,
  ]) {
    test(
      'transparent ${template.name} logo has no shadow or background in export',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'sv_logo_alpha_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final logo = img.Image(width: 100, height: 100, numChannels: 4);
        img.fillRect(
          logo,
          x1: 30,
          y1: 30,
          x2: 70,
          y2: 70,
          color: img.ColorRgba8(255, 0, 0, 255),
        );
        final logoFile = File('${directory.path}/logo.png');
        await logoFile.writeAsBytes(img.encodePng(logo));
        final source = img.Image(width: 320, height: 480);
        img.fill(source, color: img.ColorRgb8(20, 60, 120));
        final sourceFile = File('${directory.path}/source.png');
        await sourceFile.writeAsBytes(img.encodePng(source));
        final destination = '${directory.path}/stamped.jpg';
        await ImageStampService().stamp(
          source: sourceFile.path,
          destination: destination,
          time: DateTime(2026, 9, 27),
          settings: AppSettings(
            template: template,
            logoPath: logoFile.path,
            logoRadius: 0,
            companyName: '',
            showDate: false,
            showTime: false,
            showAddress: false,
            showDevice: false,
            showNote: false,
          ),
          location: const LocationStamp(),
          device: '',
          layout: const WatermarkCaptureLayout(
            previewSize: Size(320, 480),
            safeRect: Rect.fromLTWH(0, 0, 320, 480),
            watermarkSize: Size(200, 150),
            position: WatermarkPosition(x: 0, y: 0),
            margin: 12,
            mirrored: false,
            quarterTurns: 0,
          ),
        );
        final result = img.decodeJpg(await File(destination).readAsBytes())!;
        // A shadow drawn behind the logo rectangle would fill this transparent corner.
        final corner = result.getPixel(18, 18);
        expect(corner.r, closeTo(20, 3));
        expect(corner.g, closeTo(60, 3));
        expect(corner.b, closeTo(120, 3));
        expect(
          result.any((pixel) => pixel.r > 200 && pixel.g < 40 && pixel.b < 40),
          isTrue,
        );
      },
    );
  }

  test('formats visible address parts without a title', () {
    final lines =
        const LocationStamp(
          street: 'Street 19',
          province: 'Phnom Penh',
          commune: 'Mean Chey District',
          city: 'Phnom Penh',
          country: 'Cambodia',
        ).addressLinesFor(
          const AppSettings(
            language: AppLanguage.english,
            showDistrict: false,
            showVillage: false,
          ),
        );

    expect(lines, ['Street 19, Phnom Penh, Mean Chey District, Cambodia']);
  });

  test('stamps a wrapped Khmer overlay with all location details', () async {
    final directory = await Directory.systemTemp.createTemp('sv_timestamp_');
    final source = File('${directory.path}/source.jpg');
    final destination = '${directory.path}/stamped.jpg';
    await source.writeAsBytes(
      img.encodeJpg(img.Image(width: 1080, height: 1920)),
    );

    await ImageStampService().stamp(
      source: source.path,
      destination: destination,
      time: DateTime(2026, 6, 2, 10, 30),
      settings: const AppSettings(
        language: AppLanguage.khmer,
        customNote: 'ការត្រួតពិនិត្យទីតាំងសំណង់ដែលមានអត្ថបទវែង',
        logoRadius: 20,
      ),
      location: const LocationStamp(
        latitude: 11.5564,
        longitude: 104.9282,
        street: 'ផ្លូវ ១៩២',
        province: 'ភ្នំពេញ',
        commune: 'ទឹកល្អក់ទី៣',
        district: 'ទួលគោក',
        village: 'ភូមិ ១២',
        city: 'រាជធានីភ្នំពេញ',
        country: 'កម្ពុជា',
      ),
      device: 'Android',
    );

    expect(File(destination).lengthSync(), greaterThan(0));
    expect(img.decodeJpg(await File(destination).readAsBytes()), isNotNull);
    await directory.delete(recursive: true);
  });
  test('front-camera JPEG keeps the stamp at the visible bottom-left', () async {
    final directory = await Directory.systemTemp.createTemp('sv_front_stamp_');
    addTearDown(() => directory.delete(recursive: true));
    final logo = File('${directory.path}/logo.png');
    final red = img.Image(width: 24, height: 24);
    img.fill(red, color: img.ColorRgb8(255, 0, 0));
    await logo.writeAsBytes(img.encodePng(red));

    for (final zoom in [1.0, .5]) {
      for (final turns in [0, 1, 2, 3]) {
        final width = turns.isOdd ? 800 : 600;
        final height = turns.isOdd ? 600 : 800;
        final source = File('${directory.path}/source_$turns.png');
        await source.writeAsBytes(
          img.encodePng(img.Image(width: width, height: height)),
        );
        Rect? rearBounds;
        for (final mirrored in [false, true]) {
          final destination = '${directory.path}/stamp_${turns}_$mirrored.jpg';
          await ImageStampService().stamp(
            source: source.path,
            destination: destination,
            time: DateTime(2026, 9, 26),
            settings: AppSettings(
              template: WatermarkTemplate.classic,
              showNote: false,
              logoPath: logo.path,
              logoSize: 24,
              logoRadius: 0,
              companyName: '',
              showDate: false,
              showTime: false,
              showGps: false,
              showAddress: false,
              showDevice: false,
            ),
            location: const LocationStamp(),
            device: '',
            layout: WatermarkCaptureLayout(
              previewSize: const Size(300, 400),
              safeRect: const Rect.fromLTRB(10, 20, 280, 380),
              watermarkSize:
                  (turns.isOdd ? const Size(80, 100) : const Size(100, 80)) *
                  zoom,
              watermarkZoom: zoom,
              position: const WatermarkPosition(x: 0, y: 1),
              margin: 12,
              mirrored: mirrored,
              quarterTurns: turns,
            ),
          );
          final image = img.decodeJpg(await File(destination).readAsBytes())!;
          expect(image.width, width);
          expect(image.height, height);
          var left = width, top = height, right = 0, bottom = 0;
          for (final pixel in image) {
            if (pixel.r > 180 && pixel.g < 70 && pixel.b < 70) {
              if (pixel.x < left) left = pixel.x;
              if (pixel.y < top) top = pixel.y;
              if (pixel.x > right) right = pixel.x;
              if (pixel.y > bottom) bottom = pixel.y;
            }
          }
          final bounds = Rect.fromLTRB(
            left.toDouble(),
            top.toDouble(),
            (right + 1).toDouble(),
            (bottom + 1).toDouble(),
          );
          // Insets after undoing each portrait-locked preview rotation.
          final safeLeft = turns == 0 ? 10 : 20;
          final safeBottom = switch (turns) {
            1 => 290,
            3 => 280,
            _ => 380,
          };
          // Apply the photo margin once at 2x image scale; no hidden logo padding.
          expect(bounds.left, closeTo((safeLeft + 12) * 2, 2));
          expect(bounds.bottom, closeTo((safeBottom - 12) * 2, 2));
          expect(bounds.width, closeTo(48 * zoom, 2));
          if (mirrored) expect(bounds, rearBounds);
          rearBounds = bounds;
        }
      }
    }
  });
}
