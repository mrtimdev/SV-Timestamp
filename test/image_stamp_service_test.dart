import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sv_timestamp/core/services/image_stamp_service.dart';
import 'package:sv_timestamp/models/app_settings.dart';
import 'package:sv_timestamp/models/location_stamp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
