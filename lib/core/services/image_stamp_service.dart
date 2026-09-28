import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../app/constants/app_colors.dart';
import '../../models/app_settings.dart';
import '../../models/location_stamp.dart';
import '../../models/watermark_position.dart';
import '../../features/camera/layout/image_coordinate_mapper.dart';
import '../watermark/field_report_watermark.dart';
import '../watermark/watermark_contrast.dart';

class ImageStampService {
  Future<void> stamp({
    required String source,
    required String destination,
    required DateTime time,
    required AppSettings settings,
    required LocationStamp location,
    required String device,
    DeviceOrientation captureOrientation = DeviceOrientation.portraitUp,
    WatermarkCaptureLayout? layout,
    WatermarkContrast? contrast,
  }) async {
    final sourceImage = await _decode(await File(source).readAsBytes());

    contrast ??= await WatermarkContrast.fromImage(
      sourceImage,
      region: layout == null
          ? null
          : ImageCoordinateMapper.map(
              layout: layout,
              imageSize: Size(
                sourceImage.width.toDouble(),
                sourceImage.height.toDouble(),
              ),
            ).sourceRect,
    );

    if (settings.template == WatermarkTemplate.fieldReport) {
      await _stampFieldReport(
        sourceImage: sourceImage,
        contrast: contrast,
        destination: destination,
        settings: settings,
        location: location,
        device: device,
        time: time,
        layout: layout,
      );
      return;
    }

    final isLandscapeImage = sourceImage.width > sourceImage.height;
    final shortSide = isLandscapeImage ? sourceImage.height : sourceImage.width;
    final longSide = isLandscapeImage ? sourceImage.width : sourceImage.height;

    final mapped = layout == null
        ? null
        : ImageCoordinateMapper.map(
            layout: layout,
            imageSize: Size(
              sourceImage.width.toDouble(),
              sourceImage.height.toDouble(),
            ),
          );

    final imageScale = mapped?.scale ?? (shortSide / 720).clamp(1.0, 2.5);
    final scale = imageScale * (layout?.watermarkZoom ?? 1);
    final margin = (layout?.margin ?? settings.watermarkMargin) * imageScale;
    // The live overlay has no card padding; the photo margin is applied once.
    const padding = 0.0;
    final gap = 10.0 * settings.watermarkScale * scale;
    final lineGap = 3.5 * scale;
    final rowGap =
        settings.watermarkRowSpacing * settings.watermarkScale * scale;
    final logoSize = settings.logoSize * settings.watermarkScale * scale;

    // Panel width:
    // In landscape (like reference image 3), the watermark is a compact card (~40-44% of image width).
    // In portrait, the card can span up to ~90% of width or mapped preview width.
    final double defaultPanelWidth = isLandscapeImage
        ? (longSide * 0.44).clamp(360.0 * scale, 680.0 * scale)
        : sourceImage.width - margin * 2;

    final panelWidth = mapped?.rect.width ?? defaultPanelWidth;
    final contentWidth = panelWidth - padding * 2;
    final headerTextWidth = settings.showLogo
        ? (contentWidth - logoSize - gap).clamp(50.0, double.infinity)
        : contentWidth;

    final bodyEntries =
        <({IconData icon, Color iconColor, String text, Color textColor})>[
          if (settings.showGps)
            (
              icon: Icons.location_on_rounded,
              iconColor: Colors.white70,
              text:
                  'Lat: ${location.latitudeText}  Lng: ${location.longitudeText}',
              textColor: Colors.white,
            ),
          if (settings.showGpsAccuracy && location.accuracy != null)
            (
              icon: Icons.gps_fixed_rounded,
              iconColor: Colors.white70,
              text:
                  '${_label(settings, 'Accuracy', 'ភាពត្រឹមត្រូវ')}: '
                  '±${location.accuracy!.toStringAsFixed(1)} m',
              textColor: Colors.white,
            ),
          if (settings.showAddress)
            for (final line in location.addressLinesFor(settings))
              (
                icon: Icons.apartment_rounded,
                iconColor: Colors.white70,
                text: line,
                textColor: Colors.white,
              ),
          if (settings.showDevice)
            (
              icon: Icons.phone_android_rounded,
              iconColor: Colors.white60,
              text: '${_label(settings, 'Device', 'ឧបករណ៍')}: $device',
              textColor: Colors.white70,
            ),
          if (settings.showNote && settings.customNote.isNotEmpty)
            (
              icon: Icons.edit_note_rounded,
              iconColor: Colors.white,
              text:
                  '${_label(settings, 'Note', 'ចំណាំ')}: ${settings.customNote}',
              textColor: Colors.white,
            ),
          if (settings.watermarkText.isNotEmpty)
            (
              icon: Icons.label_outline_rounded,
              iconColor: Colors.white70,
              text: settings.watermarkText,
              textColor: Colors.white,
            ),
        ];

    final headerPainters = <TextPainter>[
      if (settings.companyName.isNotEmpty)
        _textPainter(
          settings.companyName,
          fontSize: (settings.fontSize + 1.8) * settings.watermarkScale * scale,
          color: AppColors.lightSurface,
          bold: true,
          maxWidth: headerTextWidth,
          shadows: contrast.textShadows(settings.watermarkScale * scale),
        ),
      if (settings.showDate || settings.showTime)
        _dateTimePainter(
          time,
          settings: settings,
          scale: scale,
          maxWidth: headerTextWidth,
          shadows: contrast.textShadows(settings.watermarkScale * scale),
        ),
    ];

    final bodyPainters = [
      for (final entry in bodyEntries)
        _textPainter(
          entry.text,
          fontSize: settings.fontSize * settings.watermarkScale * scale,
          color: entry.textColor,
          bold: entry.icon == Icons.edit_note_rounded,
          maxWidth: contentWidth - 24 * settings.watermarkScale * scale,
          shadows: contrast.textShadows(settings.watermarkScale * scale),
        ),
    ];

    final headerTextHeight = _paintersHeight(headerPainters, lineGap);
    final iconSize = settings.fontSize * settings.watermarkScale * scale * 1.15;
    final bodyHeight = bodyPainters.isEmpty
        ? 0.0
        : List.generate(
                bodyPainters.length,
                (index) => bodyPainters[index].height > iconSize
                    ? bodyPainters[index].height
                    : iconSize,
              ).fold<double>(0, (sum, height) => sum + height + rowGap) -
              rowGap;
    final headerHeight = settings.showLogo
        ? logoSize > headerTextHeight
              ? logoSize
              : headerTextHeight
        : headerTextHeight;

    final panelHeight =
        padding * 2 +
        headerHeight +
        (bodyPainters.isNotEmpty && headerPainters.isNotEmpty ? gap : 0) +
        bodyHeight;

    final outputWidth = mapped?.sourceRect.width.round() ?? sourceImage.width;
    final outputHeight =
        mapped?.sourceRect.height.round() ?? sourceImage.height;
    final availableSize = layout == null
        ? Size(outputWidth.toDouble(), outputHeight.toDouble())
        : (layout.quarterTurns.isOdd
                  ? Size(layout.safeRect.height, layout.safeRect.width)
                  : layout.safeRect.size) *
              imageScale;
    final fit = math
        .min(
          1.0,
          math.min(
            (availableSize.width - margin * 2) / panelWidth,
            (availableSize.height - margin * 2) / panelHeight,
          ),
        )
        .clamp(.001, 1.0);
    final renderedSize = Size(panelWidth * fit, panelHeight * fit);

    // Export text can wrap differently from the preview. Resolve the anchor
    // using its actual rendered height so bottom placements keep their inset.
    final placement = layout == null
        ? null
        : ImageCoordinateMapper.map(
            layout: layout,
            imageSize: Size(
              sourceImage.width.toDouble(),
              sourceImage.height.toDouble(),
            ),
            renderedWatermarkSize: renderedSize,
          );

    final right = settings.position.name.contains('Right');
    final bottom = settings.position.name.contains('bottom');

    final double left;
    if (mapped != null) {
      left = (placement!.rect.left - mapped.sourceRect.left).clamp(
        0.0,
        math.max(0.0, outputWidth - renderedSize.width),
      );
    } else {
      left = right ? sourceImage.width - renderedSize.width - margin : margin;
    }

    final double top;
    if (mapped != null) {
      top = (placement!.rect.top - mapped.sourceRect.top).clamp(
        0.0,
        math.max(0.0, outputHeight - renderedSize.height),
      );
    } else {
      top = bottom ? sourceImage.height - renderedSize.height - margin : margin;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (mapped == null) {
      canvas.drawImage(sourceImage, Offset.zero, Paint());
    } else {
      canvas.drawImageRect(
        sourceImage,
        mapped.sourceRect,
        Rect.fromLTWH(0, 0, mapped.sourceRect.width, mapped.sourceRect.height),
        Paint(),
      );
    }

    canvas.save();
    canvas.translate(left, top);
    canvas.scale(fit);
    canvas.translate(-left, -top);
    var y = top + padding;
    if (settings.showLogo) {
      final logo = await _decode(await _logoBytes(settings.logoPath));
      final logoRect = Rect.fromLTWH(left + padding, y, logoSize, logoSize);
      final logoRRect = RRect.fromRectAndRadius(
        logoRect,
        Radius.circular(settings.logoRadius * scale),
      );
      canvas.save();
      canvas.clipRRect(logoRRect);
      paintImage(
        canvas: canvas,
        rect: logoRect,
        image: logo,
        fit: BoxFit.cover,
      );
      canvas.restore();
    }

    var headerY = y + (headerHeight - headerTextHeight) / 2;
    final headerX = settings.showLogo
        ? left + padding + logoSize + gap
        : left + padding;
    for (final painter in headerPainters) {
      painter.paint(canvas, Offset(headerX, headerY));
      headerY += painter.height + lineGap;
    }

    y += headerHeight;
    if (bodyPainters.isNotEmpty && headerPainters.isNotEmpty) {
      y += gap;
    }
    for (var index = 0; index < bodyPainters.length; index++) {
      final entry = bodyEntries[index];
      final painter = bodyPainters[index];
      final icon = _iconPainter(
        entry.icon,
        entry.iconColor,
        iconSize,
        shadows: contrast.textShadows(settings.watermarkScale * scale),
      );
      icon.paint(canvas, Offset(left + padding, y));
      painter.paint(canvas, Offset(left + padding + iconSize + 7 * scale, y));
      y += (painter.height > iconSize ? painter.height : iconSize) + rowGap;
    }

    canvas.restore();
    final rendered = await recorder.endRecording().toImage(
      outputWidth,
      outputHeight,
    );
    final rgba = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) throw StateError('Unable to export stamped image.');
    final jpeg = await _encodeJpeg(
      rgba.buffer.asUint8List(),
      outputWidth,
      outputHeight,
    );
    await File(destination).writeAsBytes(jpeg);
  }

  double _paintersHeight(List<TextPainter> painters, double lineGap) {
    if (painters.isEmpty) return 0;
    return painters.fold<double>(
          0,
          (height, painter) => height + painter.height + lineGap,
        ) -
        lineGap;
  }

  Future<void> _stampFieldReport({
    required ui.Image sourceImage,
    required WatermarkContrast contrast,
    required String destination,
    required AppSettings settings,
    required LocationStamp location,
    required String device,
    required DateTime time,
    WatermarkCaptureLayout? layout,
  }) async {
    final imageSize = Size(
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );
    final mapped = layout == null
        ? null
        : ImageCoordinateMapper.map(layout: layout, imageSize: imageSize);
    final source = mapped?.sourceRect ?? (Offset.zero & imageSize);
    final width = mapped == null ? 320.0 : mapped.rect.width / mapped.scale;
    final design = FieldReportWatermark(
      settings: settings,
      contrast: contrast,
      location: location,
      device: device,
      time: time,
      width: width,
    );
    var scale = mapped?.scale ?? source.width * .88 / width;
    final margin =
        (layout?.margin ?? settings.watermarkMargin) * (mapped?.scale ?? 1);
    scale = math.min(
      scale,
      math.min(
        (source.width - margin * 2) / design.size.width,
        (source.height - margin * 2) / design.size.height,
      ),
    );
    final stampSize = Size(
      design.size.width * scale,
      design.size.height * scale,
    );
    final offset = layout == null
        ? WatermarkPosition(
            x: settings.normalizedX,
            y: settings.normalizedY,
          ).resolve(source.size, stampSize, margin: settings.watermarkMargin)
        : ImageCoordinateMapper.map(
                layout: layout,
                imageSize: imageSize,
                renderedWatermarkSize: stampSize,
              ).rect.topLeft -
              source.topLeft;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      sourceImage,
      source,
      Offset.zero & source.size,
      Paint(),
    );
    final logo = settings.showLogo
        ? await _decode(await _logoBytes(settings.logoPath))
        : null;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    design.paint(canvas, logo: logo);
    canvas.restore();
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      source.width.round(),
      source.height.round(),
    );
    final rgba = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) throw StateError('Unable to export stamped image.');
    final jpeg = await _encodeJpeg(
      rgba.buffer.asUint8List(),
      rendered.width,
      rendered.height,
    );
    await File(destination).writeAsBytes(jpeg);
    rendered.dispose();
    picture.dispose();
    sourceImage.dispose();
    logo?.dispose();
    design.dispose();
  }

  static Future<Uint8List> _encodeJpeg(Uint8List rgba, int width, int height) {
    return Isolate.run(() {
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgba.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      return Uint8List.fromList(img.encodeJpg(image, quality: 94));
    });
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required Color color,
    required bool bold,
    required double maxWidth,
    List<Shadow>? shadows,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.25,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          shadows: shadows,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  TextPainter _iconPainter(
    IconData icon,
    Color color,
    double size, {
    List<Shadow>? shadows,
  }) {
    return TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          color: color,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          shadows: shadows,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
  }

  TextPainter _dateTimePainter(
    DateTime time, {
    required AppSettings settings,
    required double scale,
    required double maxWidth,
    List<Shadow>? shadows,
  }) {
    final fontSize = settings.fontSize * settings.watermarkScale * scale;
    final base = TextStyle(
      fontSize: fontSize,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      shadows: shadows,
    );
    return TextPainter(
      text: TextSpan(
        children: [
          if (settings.showDate)
            TextSpan(text: DateFormat('yyyy-MM-dd').format(time), style: base),
          if (settings.showDate && settings.showTime)
            TextSpan(
              text: ' • ',
              style: base.copyWith(color: Colors.white54),
            ),
          if (settings.showTime)
            TextSpan(
              text: DateFormat('HH:mm:ss').format(time),
              style: base.copyWith(
                color: AppColors.lightBg,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
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
    final asset = await rootBundle.load('assets/images/sv_app_icon.png');
    return asset.buffer.asUint8List();
  }
}
