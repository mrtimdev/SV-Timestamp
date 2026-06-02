import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/utils/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/timestamp_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CameraProvider>().initialize(),
    );
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final strings = AppStrings(settings.language);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreview(camera: camera),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xB3000000),
                ],
                stops: [0, .24, .7, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: strings.text('Settings', 'ការកំណត់'),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                      const Spacer(),
                      GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        radius: 18,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: camera.location.latitude == null
                                  ? AppColors.accent
                                  : AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              camera.location.latitude == null
                                  ? 'GPS --'
                                  : 'GPS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.battery_5_bar_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppIconButton(
                        icon: camera.flashVisible
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: camera.flashVisible
                            ? AppColors.accent
                            : Colors.white,
                        tooltip: strings.text('Flash', 'ភ្លើងហ្វ្លាស'),
                        onPressed: camera.toggleFlash,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: _alignment(settings.position),
                    child: GestureDetector(
                      onPanEnd: (details) {
                        final velocity = details.velocity.pixelsPerSecond;
                        final next = _draggedPosition(
                          settings.position,
                          velocity,
                        );
                        context.read<SettingsProvider>().update(
                          settings.copyWith(position: next),
                        );
                      },
                      child: TimestampOverlay(
                        settings: settings,
                        location: camera.location,
                        device: camera.device,
                      ),
                    ),
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: .08),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIconButton(
                        icon: Icons.photo_library_outlined,
                        tooltip: strings.text('Gallery', 'វិចិត្រសាល'),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.gallery),
                      ),
                      GestureDetector(
                            onTap: () async {
                              final photo = await camera.capture();
                              if (!context.mounted || photo == null) return;
                              Navigator.pushNamed(
                                context,
                                AppRoutes.preview,
                                arguments: photo,
                              );
                            },
                            child: Container(
                              width: 88,
                              height: 88,
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondary,
                                    AppColors.primary,
                                    AppColors.accent,
                                  ],
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 3,
                                  ),
                                ),
                                child: camera.isCapturing
                                    ? const Padding(
                                        padding: EdgeInsets.all(22),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          )
                          .animate(target: camera.isCapturing ? 1 : 0)
                          .scale(end: const Offset(.88, .88), duration: 150.ms),
                      AppIconButton(
                        icon: Icons.cameraswitch_rounded,
                        tooltip: strings.text('Switch camera', 'ប្តូរកាមេរ៉ា'),
                        onPressed: camera.switchCamera,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _alignment(OverlayPosition position) => switch (position) {
    OverlayPosition.topLeft => Alignment.topLeft,
    OverlayPosition.topRight => Alignment.topRight,
    OverlayPosition.bottomLeft => Alignment.bottomLeft,
    OverlayPosition.bottomRight => Alignment.bottomRight,
  };

  OverlayPosition _draggedPosition(OverlayPosition current, Offset velocity) {
    final right = velocity.dx.abs() < 80
        ? current == OverlayPosition.topRight ||
              current == OverlayPosition.bottomRight
        : velocity.dx > 0;
    final bottom = velocity.dy.abs() < 80
        ? current == OverlayPosition.bottomLeft ||
              current == OverlayPosition.bottomRight
        : velocity.dy > 0;
    return switch ((right, bottom)) {
      (false, false) => OverlayPosition.topLeft,
      (true, false) => OverlayPosition.topRight,
      (false, true) => OverlayPosition.bottomLeft,
      (true, true) => OverlayPosition.bottomRight,
    };
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.camera});
  final CameraProvider camera;
  @override
  Widget build(BuildContext context) {
    final controller = camera.controller;
    if (controller != null && controller.value.isInitialized) {
      return Center(child: CameraPreview(controller));
    }
    return Container(
      color: const Color(0xFF111827),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              camera.isLoading
                  ? Icons.camera_alt_outlined
                  : Icons.no_photography_outlined,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              camera.isLoading
                  ? 'Opening camera...'
                  : camera.error ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (!camera.isLoading) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: camera.initialize,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
