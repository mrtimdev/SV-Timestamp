import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_settings.dart';
import '../../models/location_stamp.dart';

/// Shared vector layout for settings, the camera overlay, and full-size export.
class FieldReportWatermark {
  FieldReportWatermark({
    required this.settings,
    required LocationStamp location,
    required String device,
    required DateTime time,
    required double width,
  }) {
    final unit = width / 320;
    final font = settings.fontSize * settings.watermarkScale * unit;
    final gap = 4 * unit;
    var y = 3 * unit;
    if (settings.showLogo) {
      final logoWidth = math.min(
        settings.logoSize * settings.watermarkScale * unit,
        width * .65,
      );
      logoRect = Rect.fromLTWH(3 * unit, y, logoWidth, logoWidth * .64);
      y += logoRect!.height + gap;
    }
    if (settings.companyName.isNotEmpty &&
        settings.companyName != 'SV Timestamp') {
      y +=
          _text(
            settings.companyName,
            Offset(3 * unit, y),
            width - 6 * unit,
            font,
            Colors.white,
            unit: unit,
          ).height +
          gap;
    }
    if (settings.showTime || settings.showDate) {
      final clockHeight = 60 * unit * settings.watermarkScale;
      if (settings.showTime) {
        final timeWidth = settings.showDate ? width * .55 : width * .76;
        _fittedText(
          DateFormat('hh:mm', 'en_US').format(time),
          Rect.fromLTWH(3 * unit, y, timeWidth - 3 * unit, clockHeight),
          66 * unit,
          Colors.white,
          unit: unit,
          fillWidth: true,
        );
        _fittedText(
          DateFormat('a', 'en_US').format(time),
          Rect.fromLTWH(
            timeWidth + 2 * unit,
            y + clockHeight * .56,
            width * .075,
            clockHeight * .38,
          ),
          21 * unit,
          Colors.white,
          unit: unit,
        );
      }
      if (settings.showDate) {
        final dateX = settings.showTime ? width * .68 : 3 * unit;
        if (settings.showTime) {
          divider = Rect.fromLTWH(
            width * .65,
            y + 5 * unit,
            3 * unit,
            clockHeight - 7 * unit,
          );
        }
        _fittedText(
          DateFormat('dd MMM yyyy', 'en_US').format(time),
          Rect.fromLTWH(
            dateX,
            y + 4 * unit,
            width - dateX - 3 * unit,
            clockHeight * .4,
          ),
          19 * unit,
          Colors.white,
          unit: unit,
        );
        _fittedText(
          DateFormat('EEE', 'en_US').format(time),
          Rect.fromLTWH(
            dateX,
            y + clockHeight * .45,
            width - dateX - 3 * unit,
            clockHeight * .52,
          ),
          31 * unit,
          yellow,
          unit: unit,
        );
      }
      y += clockHeight + gap;
    }
    final khmer = settings.language == AppLanguage.khmer;
    final rows = <({IconData icon, String text, Color color})>[
      if (settings.showGps)
        (
          icon: Icons.location_on_rounded,
          text: 'Lat: ${location.latitudeText}  Lng: ${location.longitudeText}',
          color: Colors.white,
        ),
      if (settings.showGpsAccuracy && location.accuracy != null)
        (
          icon: Icons.gps_fixed_rounded,
          text:
              '${khmer ? 'ភាពត្រឹមត្រូវ' : 'Accuracy'}: ±${location.accuracy!.toStringAsFixed(1)} m',
          color: Colors.white,
        ),
      if (settings.showAddress)
        for (final line in location.addressLinesFor(settings))
          (icon: Icons.apartment_rounded, text: line, color: Colors.white),
      if (settings.showDevice)
        (
          icon: Icons.smartphone_rounded,
          text: '${khmer ? 'ឧបករណ៍' : 'Device'}: $device',
          color: Colors.white,
        ),
      if (settings.showNote && settings.customNote.trim().isNotEmpty)
        (
          icon: Icons.edit_note_rounded,
          text: '${khmer ? 'ចំណាំ' : 'Note'}: ${settings.customNote}',
          color: yellow,
        ),
      if (settings.watermarkText.isNotEmpty)
        (
          icon: Icons.label_outline_rounded,
          text: settings.watermarkText,
          color: Colors.white,
        ),
    ];
    for (final row in rows) {
      final tileSize = 28 * unit;
      final text = _text(
        row.text,
        Offset(40 * unit, y + 4 * unit),
        width - 43 * unit,
        font,
        row.color,
        unit: unit,
      );
      final height = math.max(tileSize, text.height + 8 * unit);
      _tiles.add((
        rect: Rect.fromLTWH(3 * unit, y, tileSize, tileSize),
        icon: row.icon,
        color: row.icon == Icons.location_on_rounded ? yellow : row.color,
      ));
      y += height + gap;
    }
    size = Size(width, y + 3 * unit);
    semanticsLabel = [
      if (settings.showTime) DateFormat('hh:mm a', 'en_US').format(time),
      if (settings.showDate)
        DateFormat('dd MMM yyyy EEE', 'en_US').format(time),
      ...rows.map((row) => row.text),
    ].join(', ');
  }

  static const yellow = Color(0xFFFFCE00);
  final AppSettings settings;
  late final Size size;
  late final String semanticsLabel;
  Rect? logoRect;
  Rect? divider;
  final List<_OutlinedText> _texts = [];
  final List<({Rect rect, IconData icon, Color color})> _tiles = [];

  void dispose() {
    for (final text in _texts) {
      text.fill.dispose();
      text.stroke.dispose();
    }
  }

  TextPainter _text(
    String value,
    Offset offset,
    double width,
    double font,
    Color color, {
    required double unit,
  }) {
    final text = _OutlinedText(
      value,
      offset,
      font,
      color,
      unit,
      maxWidth: width,
    );
    _texts.add(text);
    return text.fill;
  }

  void _fittedText(
    String value,
    Rect rect,
    double font,
    Color color, {
    required double unit,
    bool fillWidth = false,
  }) {
    final text = _OutlinedText(value, rect.topLeft, font, color, unit);
    text.scale = math.min(
      rect.width / text.fill.width,
      rect.height / text.fill.height,
    );
    if (fillWidth) text.horizontalScale = rect.width / text.fill.width;
    text.offset = Offset(
      rect.left,
      rect.bottom - text.fill.height * text.scale,
    );
    _texts.add(text);
  }

  void paint(Canvas canvas, {ui.Image? logo}) {
    final unit = size.width / 320;
    if (logo != null && logoRect != null) {
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          logoRect!,
          Radius.circular(settings.logoRadius * unit),
        ),
      );
      paintImage(
        canvas: canvas,
        rect: logoRect!,
        image: logo,
        fit: settings.logoPath == null ? BoxFit.cover : BoxFit.contain,
      );
      canvas.restore();
    }
    if (divider != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          divider!.inflate(1.5 * unit),
          Radius.circular(2 * unit),
        ),
        Paint()..color = Colors.black87,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(divider!, Radius.circular(unit)),
        Paint()..color = yellow,
      );
    }
    for (final tile in _tiles) {
      final rounded = RRect.fromRectAndRadius(
        tile.rect,
        Radius.circular(math.min(settings.borderRadius, 8) * unit),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = const Color(
            0xFF141921,
          ).withValues(alpha: settings.backgroundOpacity),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit,
      );
      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(tile.icon.codePoint),
          style: TextStyle(
            fontFamily: tile.icon.fontFamily,
            package: tile.icon.fontPackage,
            color: tile.color,
            fontSize: 20 * unit,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      icon.paint(
        canvas,
        tile.rect.center - Offset(icon.width / 2, icon.height / 2),
      );
      icon.dispose();
    }
    for (final text in _texts) {
      text.paint(canvas);
    }
  }
}

class _OutlinedText {
  _OutlinedText(
    String text,
    this.offset,
    double font,
    Color color,
    double unit, {
    double maxWidth = double.infinity,
  }) {
    final style = TextStyle(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans Khmer', 'Khmer Sangam MN'],
      fontSize: font,
      fontWeight: FontWeight.w900,
      height: 1.14,
      color: color,
      shadows: [
        Shadow(
          color: Colors.black87,
          blurRadius: 2 * unit,
          offset: Offset(0, unit),
        ),
      ],
    );
    fill = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: null,
          foreground: Paint()
            ..color = const Color(0xFF10141D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * unit,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
  }
  late final TextPainter fill, stroke;
  Offset offset;
  double scale = 1;
  double? horizontalScale;
  void paint(Canvas canvas) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(horizontalScale ?? scale, scale);
    stroke.paint(canvas, Offset.zero);
    fill.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
