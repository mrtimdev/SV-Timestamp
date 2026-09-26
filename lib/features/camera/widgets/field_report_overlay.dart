import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/watermark/field_report_watermark.dart';
import '../../../core/watermark/watermark_contrast.dart';
import '../../../models/app_settings.dart';
import '../../../models/location_stamp.dart';

class FieldReportOverlay extends StatefulWidget {
  const FieldReportOverlay({
    super.key,
    required this.settings,
    required this.location,
    required this.device,
    required this.time,
    required this.maxWidth,
    this.maxHeight = double.infinity,
    this.contrast = const WatermarkContrast(),
  });
  final AppSettings settings;
  final WatermarkContrast contrast;
  final LocationStamp location;
  final String device;
  final DateTime time;
  final double maxWidth, maxHeight;

  @override
  State<FieldReportOverlay> createState() => _FieldReportOverlayState();
}

class _FieldReportOverlayState extends State<FieldReportOverlay> {
  FieldReportWatermark? _layout;

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final settings = widget.settings;
      final width = math.min(widget.maxWidth, constraints.maxWidth);
      _layout?.dispose();
      final layout = _layout = FieldReportWatermark(
        settings: settings,
        contrast: widget.contrast,
        location: widget.location,
        device: widget.device,
        time: widget.time,
        width: width,
      );
      final factor = math.min(
        1.0,
        math.min(widget.maxHeight, constraints.maxHeight) / layout.size.height,
      );
      final logo = layout.logoRect;
      return Semantics(
        label: layout.semanticsLabel,
        child: SizedBox(
          width: width * factor,
          height: layout.size.height * factor,
          child: FittedBox(
            alignment: Alignment.topLeft,
            child: SizedBox.fromSize(
              size: layout.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _FieldReportPainter(layout)),
                  ),
                  if (logo != null)
                    Positioned.fromRect(
                      rect: logo,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          settings.logoRadius * width / 320,
                        ),
                        child:
                            settings.logoPath != null &&
                                File(settings.logoPath!).existsSync()
                            ? Image.file(
                                File(settings.logoPath!),
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                'assets/images/sv_app_icon.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FieldReportPainter extends CustomPainter {
  const _FieldReportPainter(this.layout);
  final FieldReportWatermark layout;
  @override
  void paint(Canvas canvas, Size size) => layout.paint(canvas);
  @override
  bool shouldRepaint(_FieldReportPainter oldDelegate) =>
      oldDelegate.layout != layout;
}
