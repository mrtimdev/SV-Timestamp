import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_settings.dart';
import '../../models/location_stamp.dart';
import 'watermark_contrast.dart';

/// Shared vector layout for settings, the camera overlay, and full-size export.
class FieldReportWatermark {
  FieldReportWatermark({
    required this.settings,
    this.contrast = const WatermarkContrast(),
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
      final inset = 3 * unit;
      final columnGap = 8 * unit;
      final dividerWidth = 2 * unit;
      final dateWidth = settings.showTime ? width * .34 : width - inset * 2;
      final timeWidth = settings.showDate
          ? width - inset * 2 - dateWidth - columnGap * 2 - dividerWidth
          : width * .76;
      if (settings.showTime) {
        _fittedText(
          DateFormat('HH:mm', 'en_US').format(time),
          Rect.fromLTWH(inset, y, timeWidth, clockHeight),
          66 * unit,
          Colors.white,
          unit: unit,
          fillWidth: true,
        );
      }
      if (settings.showDate) {
        final dividerX = inset + timeWidth + columnGap;
        final dateX = settings.showTime
            ? dividerX + dividerWidth + columnGap
            : inset;
        final dateTop = y + 4 * unit;
        final groupHeight = clockHeight - 8 * unit;
        final dateHeight = groupHeight * .42;
        final dayGap = 3 * unit;
        if (settings.showTime) {
          divider = Rect.fromLTWH(dividerX, dateTop, dividerWidth, groupHeight);
        }
        _fittedText(
          DateFormat('dd MMM yyyy', 'en_US').format(time),
          Rect.fromLTWH(dateX, dateTop, dateWidth, dateHeight),
          19 * unit,
          Colors.white,
          unit: unit,
        );
        _fittedText(
          DateFormat('EEE', 'en_US').format(time),
          Rect.fromLTWH(
            dateX,
            dateTop + dateHeight + dayGap,
            dateWidth,
            groupHeight - dateHeight - dayGap,
          ),
          31 * unit,
          Colors.white,
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
          color: Colors.white,
        ),
      if (settings.watermarkText.isNotEmpty)
        (
          icon: Icons.label_outline_rounded,
          text: settings.watermarkText,
          color: Colors.white,
        ),
    ];
    final rowGap =
        settings.watermarkRowSpacing * settings.watermarkScale * unit;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final tileSize = 28 * unit;
      final text = _text(
        row.text,
        Offset.zero,
        width - 43 * unit,
        font,
        row.color,
        unit: unit,
      );
      final height = math.max(tileSize, text.height + 8 * unit);
      text.offset = Offset(40 * unit, y + (height - text.height) / 2);
      _tiles.add((
        rect: Rect.fromLTWH(
          3 * unit,
          y + (height - tileSize) / 2,
          tileSize,
          tileSize,
        ),
        icon: row.icon,
        color: row.color,
      ));
      y += height + (index < rows.length - 1 ? rowGap : gap);
    }
    size = Size(width, y + 3 * unit);
    semanticsLabel = [
      if (settings.showTime) DateFormat('HH:mm', 'en_US').format(time),
      if (settings.showDate)
        DateFormat('dd MMM yyyy EEE', 'en_US').format(time),
      ...rows.map((row) => row.text),
    ].join(', ');
  }

  final AppSettings settings;
  final WatermarkContrast contrast;
  late final Size size;
  late final String semanticsLabel;
  Rect? logoRect;
  Rect? divider;
  final List<_OutlinedText> _texts = [];
  final List<({Rect rect, IconData icon, Color color})> _tiles = [];

  void dispose() {
    for (final text in _texts) {
      text.fill.dispose();
    }
  }

  _OutlinedText _text(
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
      shadows: contrast.textShadows(unit),
    );
    _texts.add(text);
    return text;
  }

  void _fittedText(
    String value,
    Rect rect,
    double font,
    Color color, {
    required double unit,
    bool fillWidth = false,
  }) {
    final text = _OutlinedText(
      value,
      rect.topLeft,
      font,
      color,
      unit,
      shadows: contrast.textShadows(unit),
    );
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
    if (logoRect != null) {
      contrast.paintBoxShadow(
        canvas,
        RRect.fromRectAndRadius(
          logoRect!,
          Radius.circular(settings.logoRadius * unit),
        ),
        unit,
      );
    }
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
      contrast.paintBoxShadow(
        canvas,
        RRect.fromRectAndRadius(divider!, Radius.circular(unit)),
        unit,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(divider!, Radius.circular(unit)),
        Paint()..color = Colors.white,
      );
    }
    for (final tile in _tiles) {
      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(tile.icon.codePoint),
          style: TextStyle(
            fontFamily: tile.icon.fontFamily,
            package: tile.icon.fontPackage,
            color: tile.color,
            shadows: contrast.textShadows(unit),
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
    List<Shadow>? shadows,
  }) {
    final style = TextStyle(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans Khmer', 'Khmer Sangam MN'],
      fontSize: font,
      fontWeight: FontWeight.w900,
      height: 1.14,
      color: color,
      shadows: shadows,
    );
    fill = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
  }
  late final TextPainter fill;
  Offset offset;
  double scale = 1;
  double? horizontalScale;
  double get height => fill.height;
  void paint(Canvas canvas) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(horizontalScale ?? scale, scale);
    fill.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
