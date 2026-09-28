import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../core/watermark/watermark_contrast.dart';
import '../../../models/location_stamp.dart';
import 'field_report_overlay.dart';

class TimestampOverlay extends StatelessWidget {
  const TimestampOverlay({
    super.key,
    required this.settings,
    required this.location,
    required this.device,
    this.time,
    this.isLandscape = false,
    this.maxWidth,
    this.contrast = const WatermarkContrast(),
    this.maxHeight = double.infinity,
  });

  final AppSettings settings;
  final WatermarkContrast contrast;
  final LocationStamp location;
  final String device;
  final DateTime? time;
  final bool isLandscape;
  final double? maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final now = time ?? DateTime.now();
    final screenSize = MediaQuery.sizeOf(context);

    final shortSide = screenSize.shortestSide;
    final longSide = screenSize.longestSide;

    final double panelMaxWidth =
        maxWidth ?? (isLandscape ? longSide * 0.46 : shortSide * 0.9);
    if (settings.template == WatermarkTemplate.fieldReport) {
      return FieldReportOverlay(
        settings: settings,
        contrast: contrast,
        location: location,
        device: device,
        time: now,
        maxWidth: panelMaxWidth,
        maxHeight: maxHeight,
      );
    }
    final baseFontSize = settings.fontSize * settings.watermarkScale;

    final style = TextStyle(
      color: Colors.white,
      shadows: contrast.textShadows(settings.watermarkScale),
      fontSize: baseFontSize,
      height: 1.3,
      fontWeight: FontWeight.w500,
    );

    final labelStyle = style.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontWeight: FontWeight.w400,
    );

    Widget bodyLine(String text, TextStyle textStyle) => Padding(
      padding: EdgeInsets.only(
        bottom: settings.watermarkRowSpacing * settings.watermarkScale,
      ),
      child: Text(text, style: textStyle, softWrap: true),
    );

    final headerItems = <Widget>[
      if (settings.companyName.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            settings.companyName,
            style: style.copyWith(
              color: AppColors.lightSurface,
              fontWeight: FontWeight.w800,
              fontSize: (settings.fontSize + 1.8) * settings.watermarkScale,
              letterSpacing: -0.2,
            ),
          ),
        ),
      if (settings.showDate || settings.showTime)
        Text.rich(
          TextSpan(
            children: [
              if (settings.showDate)
                TextSpan(
                  text: DateFormat('yyyy-MM-dd').format(now),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              if (settings.showDate && settings.showTime)
                TextSpan(
                  text: ' • ',
                  style: style.copyWith(color: Colors.white54),
                ),
              if (settings.showTime)
                TextSpan(
                  text: DateFormat('HH:mm:ss').format(now),
                  style: style.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: settings.timeFontSize * settings.watermarkScale,
                    color: AppColors.lightBg,
                  ),
                ),
            ],
          ),
        ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: panelMaxWidth),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section: Logo + Company Name / Date / Time
            if (settings.showLogo || headerItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      (settings.showGps ||
                          settings.showAddress ||
                          settings.showDevice ||
                          settings.showNote ||
                          settings.watermarkText.isNotEmpty)
                      ? 6.0 * settings.watermarkScale
                      : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.showLogo)
                      Padding(
                        padding: EdgeInsets.only(
                          right: 10 * settings.watermarkScale,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            settings.logoRadius * settings.watermarkScale,
                          ),
                          child:
                              settings.logoPath != null &&
                                  File(settings.logoPath!).existsSync()
                              ? Image.file(
                                  File(settings.logoPath!),
                                  width:
                                      settings.logoSize *
                                      settings.watermarkScale,
                                  height:
                                      settings.logoSize *
                                      settings.watermarkScale,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/watermark_sv_app_icon.png',
                                  width:
                                      settings.logoSize *
                                      settings.watermarkScale,
                                  height:
                                      settings.logoSize *
                                      settings.watermarkScale,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    if (headerItems.isNotEmpty)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: headerItems,
                        ),
                      ),
                  ],
                ),
              ),

            if (settings.showGps)
              bodyLine(
                '${location.latitudeText}, ${location.longitudeText}',
                style,
              ),
            if (settings.showGpsAccuracy && location.accuracy != null)
              bodyLine(
                '±${location.accuracy!.toStringAsFixed(1)} m',
                labelStyle,
              ),
            if (settings.showAddress)
              ...location
                  .addressLinesFor(settings)
                  .map((line) => bodyLine(line, style)),
            if (settings.showDevice) bodyLine(device, labelStyle),
            if (settings.showNote && settings.customNote.trim().isNotEmpty)
              bodyLine(
                settings.customNote,
                style.copyWith(fontWeight: FontWeight.w600),
              ),

            // Custom Watermark Text
            if (settings.watermarkText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 2 * settings.watermarkScale),
                child: Text(
                  settings.watermarkText,
                  style: style.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
