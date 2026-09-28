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
      final inset = 3 * unit;
      final availableWidth = width - inset * 2;
      final columnGap = 8 * unit;
      final dividerWidth = 2 * unit;
      final dayGap = 3 * unit;
      _OutlinedText? clock;
      _OutlinedText? date;
      _OutlinedText? weekday;
      if (settings.showTime) {
        clock = _text(
          DateFormat('HH:mm', 'en_US').format(time),
          Offset(inset, y),
          double.infinity,
          settings.timeFontSize * settings.watermarkScale * unit,
          Colors.white,
          unit: unit,
        );
        // Fit only when necessary; never stretch the chosen font size.
        clock.scale = math.min(1, availableWidth / clock.fill.width);
      }
      if (settings.showDate) {
        date = _text(
          DateFormat('dd MMM yyyy', 'en_US').format(time),
          Offset.zero,
          availableWidth,
          font,
          Colors.white,
          unit: unit,
        );
        weekday = _text(
          DateFormat('EEE', 'en_US').format(time),
          Offset.zero,
          availableWidth,
          font,
          Colors.white,
          unit: unit,
        );
      }
      final clockWidth = clock == null ? 0.0 : clock.fill.width * clock.scale;
      final dateWidth = date == null
          ? 0.0
          : math.max(date.fill.width, weekday!.fill.width);
      final dateHeight = date == null
          ? 0.0
          : date.height + dayGap + weekday!.height;
      final sideBySide =
          clock != null &&
          date != null &&
          clockWidth + columnGap * 2 + dividerWidth + dateWidth <=
              availableWidth;
      if (sideBySide) {
        final height = math.max(clock.height, dateHeight);
        clock.offset = Offset(inset, y + (height - clock.height) / 2);
        final dateX = inset + clockWidth + columnGap * 2 + dividerWidth;
        final dateY = y + (height - dateHeight) / 2;
        date.offset = Offset(dateX, dateY);
        weekday!.offset = Offset(dateX, dateY + date.height + dayGap);
        divider = Rect.fromLTWH(
          inset + clockWidth + columnGap,
          y,
          dividerWidth,
          height,
        );
        y += height + gap;
      } else {
        // Stack at large font sizes so the date keeps the same size as body text.
        if (clock != null) y += clock.height + gap;
        if (date != null) {
          date.offset = Offset(inset, y);
          weekday!.offset = Offset(inset, y + date.height + dayGap);
          y += dateHeight + gap;
        }
      }
    }
    final rows = <({String text, Color color})>[
      if (settings.showGps)
        (
          text: '${location.latitudeText}, ${location.longitudeText}',
          color: Colors.white,
        ),
      if (settings.showGpsAccuracy && location.accuracy != null)
        (
          text: '±${location.accuracy!.toStringAsFixed(1)} m',
          color: Colors.white,
        ),
      if (settings.showAddress)
        for (final line in location.addressLinesFor(settings))
          (text: line, color: Colors.white),
      if (settings.showDevice) (text: device, color: Colors.white),
      if (settings.showNote && settings.customNote.trim().isNotEmpty)
        (text: settings.customNote, color: Colors.white),
      if (settings.watermarkText.isNotEmpty)
        (text: settings.watermarkText, color: Colors.white),
    ];
    final rowGap =
        settings.watermarkRowSpacing * settings.watermarkScale * unit;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final text = _text(
        row.text,
        Offset(3 * unit, y),
        width - 6 * unit,
        font,
        row.color,
        unit: unit,
      );
      final height = text.height;
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
  double get height => fill.height * scale;
  void paint(Canvas canvas) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale, scale);
    fill.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
