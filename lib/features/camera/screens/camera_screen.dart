import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/utils/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../models/watermark_position.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/draggable_watermark_overlay.dart';
import '../widgets/camera_note_editor.dart';
import '../widgets/timestamp_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  Timer? _clock;
  final _previewKey = GlobalKey();
  final _topControlsKey = GlobalKey();
  final _bottomControlsKey = GlobalKey();
  final _zoomControlsKey = GlobalKey();
  Rect _safePhotoRect = Rect.zero;
  Size _watermarkSize = Size.zero;
  double _watermarkZoom = 1;
  WatermarkPosition? _captureWatermarkPosition;
  int? _watermarkQuarterTurns;
  bool _showCaptureFlash = false;
  WatermarkPosition _landscapePosition = const WatermarkPosition();

  Future<void> _editNote() async {
    final provider = context.read<SettingsProvider>();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CameraNoteEditor(
        note: provider.settings.customNote,
        strings: AppStrings(provider.settings.language),
      ),
    );
    if (result != null && mounted) await provider.updateNote(result);
  }

  Future<void> _capture(CameraProvider camera) async {
    setState(() => _showCaptureFlash = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _showCaptureFlash = false);
    });

    final photo = await camera.capture();
    if (!mounted) return;
    if (photo == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(camera.error ?? 'Could not capture photo.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.preview, arguments: photo);
  }

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
    _scheduleGeometry(camera, settings);

    final hasGps = camera.location.latitude != null;
    final turns = _deviceQuarterTurns(camera.deviceOrientation);
    final uiTurns = _uiRotationTurns(camera.deviceOrientation);
    final isLandscape = turns.isOdd;

    final wmPosition = _watermarkPosition(settings, turns);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ratio-constrained camera area ─────────────────────────────
          _RatioFrame(
            ratio: settings.cameraRatio,
            child: KeyedSubtree(
              key: _previewKey,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  _CameraPreview(camera: camera),
                  const _ViewfinderHUD(),
                  if (!_safePhotoRect.isEmpty)
                    Positioned.fromRect(
                      rect: _safePhotoRect,
                      child: DraggableWatermarkOverlay(
                        scale: settings.watermarkZoom,
                        position: _positionForScreen(wmPosition, turns),
                        margin: settings.watermarkMargin,
                        quarterTurns: turns,
                        onLayout: (size, transform) {
                          _watermarkSize = size;
                          _watermarkZoom = transform.scale;
                          _captureWatermarkPosition = _positionFromScreen(
                            transform.position,
                            turns,
                          );
                          _watermarkQuarterTurns = turns;
                          _updateCaptureLayout(camera, settings);
                        },
                        onChanged: (transform) {
                          final normalized = _positionFromScreen(
                            transform.position,
                            turns,
                          );
                          final provider = context.read<SettingsProvider>();
                          final current = provider.settings;
                          if (isLandscape) {
                            setState(() => _landscapePosition = normalized);
                            if (transform.scale != current.watermarkZoom) {
                              provider.update(
                                current.copyWith(
                                  watermarkZoom: transform.scale,
                                ),
                              );
                            }
                          } else {
                            provider.update(
                              current.copyWith(
                                watermarkZoom: transform.scale,
                                normalizedX: normalized.x,
                                normalizedY: normalized.y,
                              ),
                            );
                          }
                        },
                        child: TimestampOverlay(
                          settings: settings,
                          location: camera.location,
                          device: camera.device,
                          isLandscape: isLandscape,
                          maxHeight:
                              ((isLandscape
                                      ? _safePhotoRect.width
                                      : _safePhotoRect.height) -
                                  settings.watermarkMargin * 2) *
                              (settings.template ==
                                      WatermarkTemplate.fieldReport
                                  ? .85
                                  : 1),
                          maxWidth: isLandscape
                              ? (_safePhotoRect.longestSide * 0.44)
                                    .clamp(300.0, 420.0)
                                    .clamp(
                                      0.0,
                                      _safePhotoRect.height -
                                          settings.watermarkMargin * 2,
                                    )
                              : _safePhotoRect.shortestSide * 0.92,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Vignette gradient ──────────────────────────────────────────
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, .2, .75, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),

          // ── Capture Flash Overlay ──────────────────────────────────────
          if (_showCaptureFlash)
            Container(
              color: Colors.white.withValues(alpha: 0.85),
            ).animate().fadeOut(duration: 120.ms),

          // ── Camera controls HUD ────────────────────────────────────────
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Top bar: Settings, GPS Status Badge, Flash
                KeyedSubtree(
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: uiTurns,
                        duration: const Duration(milliseconds: 250),
                        child: AppIconButton(
                          icon: Icons.settings_rounded,
                          tooltip: strings.text('Settings', 'ការកំណត់'),
                          size: 44,
                          iconSize: 21,
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _GpsStatusBadge(
                            hasGps: hasGps,
                            accuracy: camera.location.accuracy,
                            quarterTurns: turns,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: uiTurns,
                        duration: const Duration(milliseconds: 250),
                        child: AppIconButton(
                          icon: camera.flashVisible
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: camera.flashVisible
                              ? AppColors.amberAccent
                              : Colors.white,
                          backgroundColor: camera.flashVisible
                              ? AppColors.amberAccent.withValues(alpha: 0.2)
                              : null,
                          borderColor: camera.flashVisible
                              ? AppColors.amberAccent.withValues(alpha: 0.4)
                              : null,
                          size: 44,
                          iconSize: 21,
                          tooltip: strings.text('Flash', 'ភ្លើងហ្វ្លាស'),
                          onPressed: camera.toggleFlash,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  key: _topControlsKey,
                  children: [
                    Expanded(
                      child: _RatioSelector(
                        selected: settings.cameraRatio,
                        uiTurns: uiTurns,
                        onChanged: (ratio) {
                          context.read<SettingsProvider>().update(
                            settings.copyWith(cameraRatio: ratio),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotatedBox(
                      quarterTurns: turns,
                      child: AppIconButton(
                        key: const ValueKey('edit-camera-note'),
                        icon: Icons.edit_note_rounded,
                        size: 40,
                        color: AppColors.amberAccent,
                        tooltip: strings.text('Edit note', 'កែសម្រួលចំណាំ'),
                        onPressed: camera.isCapturing ? null : _editNote,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (camera.maxZoom > camera.minZoom)
                  Padding(
                    key: _zoomControlsKey,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ZoomSlider(camera: camera, uiTurns: uiTurns),
                  ),
                KeyedSubtree(
                  key: _bottomControlsKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _CaptureDock(
                        camera: camera,
                        strings: strings,
                        uiTurns: uiTurns,
                        onCapture: () => _capture(camera),
                        onGallery: () =>
                            Navigator.pushNamed(context, AppRoutes.gallery),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleGeometry(CameraProvider camera, AppSettings settings) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final preview =
          _previewKey.currentContext?.findRenderObject() as RenderBox?;
      if (preview == null) return;
      final m = settings.watermarkMargin;
      final topControls =
          _topControlsKey.currentContext?.findRenderObject() as RenderBox?;
      final bottomControls =
          (_zoomControlsKey.currentContext ?? _bottomControlsKey.currentContext)
                  ?.findRenderObject()
              as RenderBox?;
      final top = topControls == null
          ? m
          : preview
                    .globalToLocal(
                      topControls.localToGlobal(
                        Offset(0, topControls.size.height),
                      ),
                    )
                    .dy +
                8;
      final bottom = bottomControls == null
          ? preview.size.height - m
          : preview
                    .globalToLocal(bottomControls.localToGlobal(Offset.zero))
                    .dy -
                8;
      final next = Rect.fromLTRB(
        m,
        top.clamp(m, preview.size.height - m),
        preview.size.width - m,
        bottom.clamp(m, preview.size.height - m),
      );
      if (next != _safePhotoRect) setState(() => _safePhotoRect = next);
      _updateCaptureLayout(
        camera,
        settings,
        previewSize: preview.size,
        safeRect: next,
      );
    });
  }

  void _updateCaptureLayout(
    CameraProvider camera,
    AppSettings settings, {
    Size? previewSize,
    Rect? safeRect,
  }) {
    final controller = camera.controller;
    if (controller == null || _watermarkSize.isEmpty) return;
    final turns = _deviceQuarterTurns(camera.deviceOrientation);
    if (_watermarkQuarterTurns != turns) return;
    final position =
        _captureWatermarkPosition ?? _watermarkPosition(settings, turns);
    camera.updateCaptureLayout(
      WatermarkCaptureLayout(
        previewSize:
            previewSize ??
            (_previewKey.currentContext?.findRenderObject() as RenderBox).size,
        safeRect: safeRect ?? _safePhotoRect,
        watermarkSize: _watermarkSize,
        position: position,
        margin: settings.watermarkMargin,
        mirrored:
            controller.description.lensDirection == CameraLensDirection.front,
        quarterTurns: turns,
        watermarkZoom: _watermarkZoom,
      ),
    );
  }

  // Landscape starts at bottom-left, then retains the user's dragged position
  // in upright photo coordinates across either landscape direction.
  WatermarkPosition _watermarkPosition(AppSettings settings, int turns) =>
      turns.isOdd
      ? _landscapePosition
      : WatermarkPosition(x: settings.normalizedX, y: settings.normalizedY);

  int _deviceQuarterTurns(DeviceOrientation orientation) =>
      switch (orientation) {
        DeviceOrientation.landscapeLeft => 1,
        DeviceOrientation.landscapeRight => 3,
        DeviceOrientation.portraitDown => 2,
        DeviceOrientation.portraitUp => 0,
      };

  WatermarkPosition _positionForScreen(WatermarkPosition position, int turns) =>
      switch (turns % 4) {
        1 => WatermarkPosition(x: 1 - position.y, y: position.x),
        2 => WatermarkPosition(x: 1 - position.x, y: 1 - position.y),
        3 => WatermarkPosition(x: position.y, y: 1 - position.x),
        _ => position,
      };

  WatermarkPosition _positionFromScreen(
    WatermarkPosition position,
    int turns,
  ) => switch (turns % 4) {
    1 => WatermarkPosition(x: position.y, y: 1 - position.x),
    2 => WatermarkPosition(x: 1 - position.x, y: 1 - position.y),
    3 => WatermarkPosition(x: 1 - position.y, y: position.x),
    _ => position,
  };

  double _uiRotationTurns(DeviceOrientation orientation) =>
      switch (orientation) {
        DeviceOrientation.landscapeLeft => 0.25,
        DeviceOrientation.landscapeRight => -0.25,
        DeviceOrientation.portraitDown => 0.5,
        DeviceOrientation.portraitUp => 0.0,
      };
}

// ── Ratio frame ──────────────────────────────────────────────────────────────

class _RatioFrame extends StatelessWidget {
  const _RatioFrame({required this.ratio, required this.child});
  final CameraRatio ratio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ratio == CameraRatio.full) {
      return SizedBox.expand(child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final ar = ratio.w / ratio.h;
        var width = constraints.maxWidth;
        var height = width / ar;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * ar;
        }
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            child: child,
          ),
        );
      },
    );
  }
}

// ── Ratio selector ───────────────────────────────────────────────────────────

class _RatioSelector extends StatelessWidget {
  const _RatioSelector({
    required this.selected,
    required this.uiTurns,
    required this.onChanged,
  });
  final CameraRatio selected;
  final double uiTurns;
  final ValueChanged<CameraRatio> onChanged;

  @override
  Widget build(BuildContext context) {
    // Keep the controls in their rail and rotate each label within its button.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        radius: 20,
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        borderColor: Colors.white.withValues(alpha: 0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ratio in CameraRatio.values)
              GestureDetector(
                onTap: () => onChanged(ratio),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: ratio == selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.transparent,
                  ),
                  child: RotatedBox(
                    quarterTurns: (uiTurns * 4).round(),
                    child: Text(
                      ratio.label,
                      style: TextStyle(
                        color: ratio == selected
                            ? AppColors.primaryLight
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: ratio == selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Camera preview ───────────────────────────────────────────────────────────

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.camera});
  final CameraProvider camera;
  @override
  Widget build(BuildContext context) {
    final controller = camera.controller;
    if (controller != null && controller.value.isInitialized) {
      final previewSize = controller.value.previewSize!;
      final quarterTurns = switch (camera.deviceOrientation) {
        DeviceOrientation.landscapeLeft => 1,
        DeviceOrientation.landscapeRight => 3,
        DeviceOrientation.portraitDown => 2,
        DeviceOrientation.portraitUp => 0,
      };
      final isLandscape = quarterTurns.isOdd;
      return ClipRect(
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: isLandscape ? previewSize.width : previewSize.height,
                height: isLandscape ? previewSize.height : previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
      );
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

// ── Viewfinder Tech HUD ───────────────────────────────────────────────────────

class _ViewfinderHUD extends StatelessWidget {
  const _ViewfinderHUD();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 120),
          child: CustomPaint(size: Size.infinite, painter: _HUDPainter()),
        ),
      ),
    );
  }
}

class _HUDPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const cornerLen = 22.0;

    // Top-Left Corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-Right Corner
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLen, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLen),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLen),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLen),
      paint,
    );

    // Center subtle crosshair
    final center = Offset(size.width / 2, size.height / 2);
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Capture dock ─────────────────────────────────────────────────────────────

class _CaptureDock extends StatelessWidget {
  const _CaptureDock({
    required this.camera,
    required this.strings,
    required this.uiTurns,
    required this.onCapture,
    required this.onGallery,
  });

  final CameraProvider camera;
  final AppStrings strings;
  final double uiTurns;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final ready = camera.controller?.value.isInitialized ?? false;
    return GlassPanel(
      radius: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      borderColor: Colors.white.withValues(alpha: 0.16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onGallery,
              child: AnimatedRotation(
                turns: uiTurns,
                duration: const Duration(milliseconds: 250),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1.5),
                        image: camera.lastPhotoPath != null
                            ? DecorationImage(
                                image: FileImage(File(camera.lastPhotoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: camera.lastPhotoPath == null
                          ? const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white54,
                              size: 22,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.text('Preview', 'មើលរូប'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Semantics(
            button: true,
            enabled: ready && !camera.isCapturing,
            label: strings.text('Take photo', 'ថតរូប'),
            child: AnimatedScale(
              scale: camera.isCapturing ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                onTap: ready && !camera.isCapturing ? onCapture : null,
                child: Container(
                  width: 78,
                  height: 78,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ready ? Colors.white : Colors.white24,
                      width: 3,
                    ),
                  ),
                  child: camera.isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready ? Colors.white : Colors.white24,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Flip Camera Action
          Expanded(
            child: _DockAction(
              icon: Icons.cameraswitch_rounded,
              label: strings.text('Flip', 'ប្តូរ'),
              uiTurns: uiTurns,
              onPressed: ready && !camera.isCapturing
                  ? camera.switchCamera
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.uiTurns,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final double uiTurns;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: AnimatedRotation(
          turns: uiTurns,
          duration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: onPressed != null ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: onPressed != null ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Zoom slider ─────────────────────────────────────────────────────────────

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({required this.camera, required this.uiTurns});
  final CameraProvider camera;
  final double uiTurns;

  @override
  Widget build(BuildContext context) {
    final zoom = camera.currentZoom.clamp(camera.minZoom, camera.maxZoom);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        radius: 28,
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 44,
              child: Center(
                child: RotatedBox(
                  quarterTurns: (uiTurns * 4).round(),
                  child: Text(
                    '${zoom.toStringAsFixed(1)}×',
                    style: const TextStyle(
                      color: AppColors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                key: const ValueKey('camera-zoom-slider'),
                min: camera.minZoom,
                max: camera.maxZoom,
                value: zoom,
                activeColor: AppColors.amberAccent,
                inactiveColor: Colors.white24,
                label: '${zoom.toStringAsFixed(1)}×',
                semanticFormatterCallback: (value) =>
                    '${value.toStringAsFixed(1)}× zoom',
                onChanged: camera.isCapturing ? null : camera.setZoom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsStatusBadge extends StatelessWidget {
  const _GpsStatusBadge({
    required this.hasGps,
    required this.accuracy,
    required this.quarterTurns,
  });

  final bool hasGps;
  final double? accuracy;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final color = hasGps ? AppColors.success : AppColors.error;
    final landscape = quarterTurns.isOdd;
    // Rotate compact labels inside the badge, keeping the top bar compact.
    return SizedBox(
      height: 44,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: GlassPanel(
          key: const ValueKey('gps-status-badge'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          radius: 20,
          backgroundColor: Colors.black.withValues(alpha: 0.45),
          borderColor: color.withValues(alpha: 0.4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RotatedBox(
                quarterTurns: quarterTurns,
                child: Text(
                  hasGps
                      ? (landscape ? 'GPS\nACTIVE' : 'GPS ACTIVE')
                      : (landscape ? 'NO\nGPS' : 'NO GPS'),
                  key: const ValueKey('gps-status-label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasGps ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (hasGps && accuracy != null) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: 10, color: Colors.white24),
                const SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: quarterTurns,
                  child: Text(
                    '±${accuracy!.toStringAsFixed(0)}m',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
