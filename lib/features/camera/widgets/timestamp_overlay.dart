import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../models/location_stamp.dart';
import '../../../core/utils/app_strings.dart';

class TimestampOverlay extends StatelessWidget {
  const TimestampOverlay({
    super.key,
    required this.settings,
    required this.location,
    required this.device,
    this.time,
  });
  final AppSettings settings;
  final LocationStamp location;
  final String device;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final now = time ?? DateTime.now();
    final strings = AppStrings(settings.language);
    final style = TextStyle(
      color: Colors.white,
      fontSize: settings.fontSize,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
        maxHeight: MediaQuery.sizeOf(context).height * .56,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: settings.backgroundOpacity),
        borderRadius: BorderRadius.circular(settings.borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settings.showLogo)
              ClipRRect(
                borderRadius: BorderRadius.circular(settings.logoRadius),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      settings.logoPath != null &&
                          File(settings.logoPath!).existsSync()
                      ? Image.file(
                          File(settings.logoPath!),
                          height: settings.logoSize,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        )
                      : Image.asset(
                          'assets/images/sv_timestamp_logo.png',
                          height: settings.logoSize,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                ),
              ),
            if (settings.companyName.isNotEmpty)
              Text(
                settings.companyName,
                style: style.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: settings.fontSize + 2,
                ),
              ),
            if (settings.showDate)
              Text(DateFormat('yyyy-MM-dd').format(now), style: style),
            if (settings.showTime)
              Text(DateFormat('hh:mm:ss a').format(now), style: style),
            if (settings.showGps)
              Text(
                'Lat: ${location.latitudeText}  Lng: ${location.longitudeText}',
                style: style,
              ),
            if (settings.showAddress)
              ...location
                  .addressLinesFor(settings)
                  .map((line) => Text(line, style: style, softWrap: true)),
            if (settings.showDevice)
              Text(
                '${strings.text('Device', 'ឧបករណ៍')}: $device',
                style: style,
              ),
            if (settings.showNote && settings.customNote.isNotEmpty)
              Text(
                '${strings.text('Note', 'ចំណាំ')}: ${settings.customNote}',
                style: style,
                softWrap: true,
              ),
            if (settings.watermarkText.isNotEmpty)
              Text(settings.watermarkText, style: style),
          ],
        ),
      ),
    );
  }
}
