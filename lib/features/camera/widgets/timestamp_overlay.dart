import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../core/watermark/watermark_contrast.dart';
import '../../../models/location_stamp.dart';
import '../../../core/utils/app_strings.dart';
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
    final strings = AppStrings(settings.language);
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              settings.logoRadius * settings.watermarkScale,
                            ),
                            boxShadow: contrast.boxShadows(
                              settings.watermarkScale,
                            ),
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
                                    'assets/images/sv_app_icon.png',
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

            // GPS Coordinates
            if (settings.showGps)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      settings.watermarkRowSpacing * settings.watermarkScale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2 * settings.watermarkScale,
                        right: 5 * settings.watermarkScale,
                      ),
                      child: Icon(
                        shadows: contrast.textShadows(settings.watermarkScale),
                        Icons.location_on_rounded,
                        size: 13 * settings.watermarkScale,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Lat: ${location.latitudeText}  Lng: ${location.longitudeText}',
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),

            // GPS Accuracy
            if (settings.showGpsAccuracy && location.accuracy != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      settings.watermarkRowSpacing * settings.watermarkScale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2 * settings.watermarkScale,
                        right: 5 * settings.watermarkScale,
                      ),
                      child: Icon(
                        shadows: contrast.textShadows(settings.watermarkScale),
                        Icons.gps_fixed_rounded,
                        size: 12 * settings.watermarkScale,
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${strings.text('Accuracy', 'ភាពត្រឹមត្រូវ')}: ±${location.accuracy!.toStringAsFixed(1)} m',
                        style: labelStyle,
                      ),
                    ),
                  ],
                ),
              ),

            // Address Details
            if (settings.showAddress)
              ...location
                  .addressLinesFor(settings)
                  .map(
                    (line) => Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            settings.watermarkRowSpacing *
                            settings.watermarkScale,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 2 * settings.watermarkScale,
                              right: 5 * settings.watermarkScale,
                            ),
                            child: Icon(
                              shadows: contrast.textShadows(
                                settings.watermarkScale,
                              ),
                              Icons.apartment_rounded,
                              size: 12 * settings.watermarkScale,
                              color: Colors.white60,
                            ),
                          ),
                          Expanded(
                            child: Text(line, style: style, softWrap: true),
                          ),
                        ],
                      ),
                    ),
                  ),

            // Device
            if (settings.showDevice)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      settings.watermarkRowSpacing * settings.watermarkScale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2 * settings.watermarkScale,
                        right: 5 * settings.watermarkScale,
                      ),
                      child: Icon(
                        shadows: contrast.textShadows(settings.watermarkScale),
                        Icons.smartphone_rounded,
                        size: 12 * settings.watermarkScale,
                        color: Colors.white60,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${strings.text('Device', 'ឧបករណ៍')}: $device',
                        style: labelStyle,
                      ),
                    ),
                  ],
                ),
              ),

            // Custom Note
            if (settings.showNote && settings.customNote.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      settings.watermarkRowSpacing * settings.watermarkScale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2 * settings.watermarkScale,
                        right: 5 * settings.watermarkScale,
                      ),
                      child: Icon(
                        shadows: contrast.textShadows(settings.watermarkScale),
                        Icons.edit_note_rounded,
                        size: 13 * settings.watermarkScale,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${strings.text('Note', 'ចំណាំ')}: ${settings.customNote}',
                        style: style.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
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
