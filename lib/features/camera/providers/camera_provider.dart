import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import '../../../core/services/device_service.dart';
import '../../../core/services/image_stamp_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/watermark/watermark_contrast.dart';
import '../../../models/captured_photo.dart';
import '../../../models/app_settings.dart';
import '../../../models/location_stamp.dart';
import '../../../models/watermark_position.dart';
import '../../settings/providers/settings_provider.dart';
import '../layout/camera_preview_layout.dart';

class CameraProvider extends ChangeNotifier {
  CameraProvider(this.settingsProvider);
  final SettingsProvider settingsProvider;
  final storage = PhotoStorageService();
  final _location = LocationService();
  final _device = DeviceService();
  final _stamper = ImageStampService();
  CameraController? controller;
  DeviceOrientation deviceOrientation = DeviceOrientation.portraitUp;
  LocationStamp location = const LocationStamp();
  String device = 'Loading device...';
  bool isLoading = true, isCapturing = false, flashVisible = false;
  String? error;
  WatermarkCaptureLayout? captureLayout;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  Future<void> _zoomQueue = Future.value();
  String? lastPhotoPath;
  WatermarkContrast watermarkContrast = const WatermarkContrast();
  bool _hasContrastSample = false;
  DateTime? _lastContrastSample;

  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  void updateCaptureLayout(WatermarkCaptureLayout layout) {
    captureLayout = layout;
  }

  Future<void> initialize() async {
    isLoading = true;
    error = null;
    notifyListeners();
    await refreshLocation();
    device = await _device.name();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      await _open(cameras.first);
    } catch (e) {
      error = 'Camera is unavailable. Check camera permission and try again.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    location = await _location.locate(
      localeIdentifier: AppStrings(
        settingsProvider.settings.language,
      ).localeIdentifier,
    );
    notifyListeners();
  }

  Future<void> _open(CameraDescription camera) async {
    controller?.removeListener(_handleCameraValueChanged);
    await controller?.dispose();
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
    deviceOrientation = controller!.value.deviceOrientation;
    _minZoom = await controller!.getMinZoomLevel();
    _maxZoom = await controller!.getMaxZoomLevel();
    _currentZoom = 1.0.clamp(_minZoom, _maxZoom);
    controller!.addListener(_handleCameraValueChanged);
    _hasContrastSample = false;
    _lastContrastSample = null;
    await _startContrastStream(controller!);
    notifyListeners();
  }

  Future<void> _startContrastStream(CameraController active) async {
    if (active != controller || active.value.isStreamingImages) return;
    try {
      await active.startImageStream((image) {
        if (active != controller || isCapturing) return;
        final now = DateTime.now();
        if (_lastContrastSample != null &&
            now.difference(_lastContrastSample!).inMilliseconds < 350) {
          return;
        }
        _lastContrastSample = now;
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        var previewSize = captureLayout?.previewSize ?? imageSize;
        // Sampling the centered crop is invariant to rotation and mirroring.
        // Sensor buffers and the portrait-locked UI may have swapped axes.
        if ((imageSize.width > imageSize.height) !=
            (previewSize.width > previewSize.height)) {
          previewSize = Size(previewSize.height, previewSize.width);
        }
        final brightness = WatermarkContrast.cameraBrightness(
          image,
          region: CameraPreviewLayout.coverSourceRect(imageSize, previewSize),
        );
        if (brightness == null) return;
        final next = WatermarkContrast.fromBrightness(
          brightness,
          previous: _hasContrastSample ? watermarkContrast : null,
        );
        _hasContrastSample = true;
        if (next.darkScene == watermarkContrast.darkScene) return;
        watermarkContrast = next;
        notifyListeners();
      });
    } on CameraException {
      // Some devices cannot stream alongside preview. Keep the readable
      // fallback halo and determine contrast from the captured photo instead.
    } on UnimplementedError {
      // Image streams are not available on every camera backend.
    }
  }

  void _handleCameraValueChanged() {
    final next = controller?.value.deviceOrientation;
    if (next == null || next == deviceOrientation) return;
    deviceOrientation = next;
    notifyListeners();
  }

  /// Fallback for captures without a measured preview layout.
  OverlayPosition effectiveStampPosition(OverlayPosition preferred) {
    final isLandscape =
        deviceOrientation == DeviceOrientation.landscapeLeft ||
        deviceOrientation == DeviceOrientation.landscapeRight;
    if (!isLandscape) return preferred;
    return OverlayPosition.bottomLeft;
  }

  Future<void> switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2 || controller == null) return;
    final current = controller!.description;
    await _open(
      cameras.firstWhere(
        (camera) => camera.lensDirection != current.lensDirection,
        orElse: () => cameras.first,
      ),
    );
  }

  Future<void> toggleFlash() async {
    if (controller == null) return;
    flashVisible = !flashVisible;
    await controller!.setFlashMode(
      flashVisible ? FlashMode.torch : FlashMode.off,
    );
    notifyListeners();
  }

  Future<void> setZoom(double zoom) async {
    final activeController = controller;
    if (activeController == null) return;
    final target = zoom.clamp(_minZoom, _maxZoom);
    _currentZoom = target;
    notifyListeners();
    // Serialize hardware updates and skip values superseded by a slider drag.
    _zoomQueue = _zoomQueue.then((_) async {
      if (activeController != controller || target != _currentZoom) return;
      try {
        await activeController.setZoomLevel(target);
      } on CameraException {
        if (activeController != controller) return;
        error = 'Could not adjust zoom. Please try again.';
        notifyListeners();
      }
    });
    await _zoomQueue;
  }

  Future<CapturedPhoto?> capture() async {
    if (controller == null || !controller!.value.isInitialized || isCapturing) {
      return null;
    }
    isCapturing = true;
    // Freeze geometry before the camera's asynchronous capture starts.
    final captureOrientation = deviceOrientation;
    final layout = captureLayout;
    final settings = settingsProvider.settings.copyWith(
      position: effectiveStampPosition(settingsProvider.settings.position),
    );
    final captureLocation = location;
    final captureDevice = device;
    final contrast = _hasContrastSample ? watermarkContrast : null;
    final activeController = controller!;
    final now = DateTime.now();
    notifyListeners();
    try {
      // Stop analysis for devices that cannot capture while streaming.
      if (activeController.value.isStreamingImages) {
        await activeController.stopImageStream();
      }
      final raw = await activeController.takePicture();
      final destination = await storage.newPath();
      await _stamper.stamp(
        source: raw.path,
        destination: destination,
        time: now,
        settings: settings,
        location: captureLocation,
        device: captureDevice,
        captureOrientation: captureOrientation,
        layout: layout,
        contrast: contrast,
      );
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putImage(destination, album: 'SV Timestamp');
      } catch (_) {
        // The app's private copy remains available when system gallery access is denied.
      }
      await File(raw.path).delete();
      lastPhotoPath = destination;
      return CapturedPhoto(path: destination, capturedAt: now);
    } catch (e) {
      error = 'Could not save photo. Please try again.';
      return null;
    } finally {
      isCapturing = false;
      if (controller == activeController) {
        await _startContrastStream(activeController);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    final activeController = controller;
    controller = null;
    activeController?.removeListener(_handleCameraValueChanged);
    activeController?.dispose();
    super.dispose();
  }
}
