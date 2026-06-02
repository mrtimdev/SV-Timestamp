import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../models/app_settings.dart';
import '../../models/location_stamp.dart';

class ImageStampService {
  Future<void> stamp({
    required String source,
    required String destination,
    required DateTime time,
    required AppSettings settings,
    required LocationStamp location,
    required String device,
  }) async {
    final sourceImage = await _decode(await File(source).readAsBytes());
    final scale = (sourceImage.width / 1080).clamp(.75, 3.0);
    final padding = 22.0 * scale;
    final logoSize = settings.logoSize * scale;
    final maxPanelWidth = sourceImage.width * .82;
    final maxTextWidth = maxPanelWidth - padding * 2;
    final lines = <String>[
      if (settings.companyName.isNotEmpty) settings.companyName,
      if (settings.showDate) DateFormat('yyyy-MM-dd').format(time),
      if (settings.showTime) DateFormat('hh:mm:ss a').format(time),
      if (settings.showGps)
        'Lat: ${location.latitudeText}  Lng: ${location.longitudeText}',
      if (settings.showAddress) ...location.addressLinesFor(settings),
      if (settings.showDevice)
        '${_label(settings, 'Device', 'ឧបករណ៍')}: $device',
      if (settings.showNote && settings.customNote.isNotEmpty)
        '${_label(settings, 'Note', 'ចំណាំ')}: ${settings.customNote}',
      if (settings.watermarkText.isNotEmpty) settings.watermarkText,
    ];
    final painters = [
      for (var index = 0; index < lines.length; index++)
        _textPainter(
          lines[index],
          fontSize: (settings.fontSize + (index == 0 ? 2 : 0)) * scale,
          color: index == 0 ? const Color(0xFFF97316) : Colors.white,
          bold: index == 0,
          maxWidth: maxTextWidth,
        ),
    ];
    final widestText = painters.fold<double>(
      0,
      (width, painter) => painter.width > width ? painter.width : width,
    );
    final panelWidth = (widestText + padding * 2).clamp(
      220.0 * scale,
      maxPanelWidth,
    );
    final textHeight = painters.fold<double>(
      0,
      (height, painter) => height + painter.height + 5 * scale,
    );
    final panelHeight =
        padding * 2 +
        textHeight +
        (settings.showLogo ? logoSize + 10 * scale : 0);
    final margin = 28.0 * scale;
    final right = settings.position.name.contains('Right');
    final bottom = settings.position.name.contains('bottom');
    final left = right ? sourceImage.width - panelWidth - margin : margin;
    final top = bottom ? sourceImage.height - panelHeight - margin : margin;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, panelWidth, panelHeight),
      Radius.circular(settings.borderRadius * scale),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(sourceImage, Offset.zero, Paint());
    canvas.drawRRect(
      panel,
      Paint()
        ..color = Colors.black.withValues(alpha: settings.backgroundOpacity),
    );
    var y = top + padding;
    if (settings.showLogo) {
      final logo = await _decode(await _logoBytes(settings.logoPath));
      final logoRect = Rect.fromLTWH(left + padding, y, logoSize, logoSize);
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          logoRect,
          Radius.circular(settings.logoRadius * scale),
        ),
      );
      paintImage(
        canvas: canvas,
        rect: logoRect,
        image: logo,
        fit: BoxFit.cover,
      );
      canvas.restore();
      y += logoSize + 10 * scale;
    }
    for (final painter in painters) {
      painter.paint(canvas, Offset(left + padding, y));
      y += painter.height + 5 * scale;
    }
    final rendered = await recorder.endRecording().toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final decoded = img.decodePng(png!.buffer.asUint8List());
    if (decoded == null) throw StateError('Unable to export stamped image.');
    await File(destination).writeAsBytes(img.encodeJpg(decoded, quality: 94));
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required Color color,
    required bool bold,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.25,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  String _label(AppSettings settings, String english, String khmer) =>
      settings.language == AppLanguage.khmer ? khmer : english;

  Future<ui.Image> _decode(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<Uint8List> _logoBytes(String? logoPath) async {
    if (logoPath != null && File(logoPath).existsSync()) {
      return File(logoPath).readAsBytes();
    }
    final asset = await rootBundle.load('assets/images/sv_timestamp_logo.png');
    return asset.buffer.asUint8List();
  }
}
