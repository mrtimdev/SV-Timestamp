import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Fits the live texture into the portrait-locked camera frame.
class OrientedCameraPreview extends StatelessWidget {
  const OrientedCameraPreview({
    super.key,
    required this.controller,
    required this.quarterTurns,
  });

  final CameraController controller;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize!;
    final android = defaultTargetPlatform == TargetPlatform.android;
    // CameraX already orients its texture to the locked Android display. Only
    // the controls/watermark rotate physically. Avoid CameraPreview's additional
    // Android rotation, which also changes when locking the photo orientation.
    final turns = android ? 0 : quarterTurns;
    final landscape = turns.isOdd;
    return ClipRect(
      child: RotatedBox(
        quarterTurns: turns,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: landscape ? preview.width : preview.height,
              height: landscape ? preview.height : preview.width,
              child: android
                  ? controller.buildPreview()
                  : CameraPreview(controller),
            ),
          ),
        ),
      ),
    );
  }
}
