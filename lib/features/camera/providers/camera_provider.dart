import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../../core/services/device_service.dart';
import '../../../core/services/image_stamp_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../core/utils/app_strings.dart';
import '../../../models/captured_photo.dart';
import '../../../models/location_stamp.dart';
import '../../settings/providers/settings_provider.dart';

class CameraProvider extends ChangeNotifier {
  CameraProvider(this.settingsProvider);
  final SettingsProvider settingsProvider;
  final storage = PhotoStorageService();
  final _location = LocationService();
  final _device = DeviceService();
  final _stamper = ImageStampService();
  CameraController? controller;
  LocationStamp location = const LocationStamp();
  String device = 'Loading device...';
  bool isLoading = true, isCapturing = false, flashVisible = false;
  String? error;

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
    await controller?.dispose();
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller!.initialize();
    notifyListeners();
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

  Future<CapturedPhoto?> capture() async {
    if (controller == null || !controller!.value.isInitialized || isCapturing) {
      return null;
    }
    isCapturing = true;
    notifyListeners();
    try {
      final raw = await controller!.takePicture();
      final destination = await storage.newPath();
      final now = DateTime.now();
      await _stamper.stamp(
        source: raw.path,
        destination: destination,
        time: now,
        settings: settingsProvider.settings,
        location: location,
        device: device,
      );
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putImage(destination, album: 'SV Timestamp');
      } catch (_) {
        // The app's private copy remains available when system gallery access is denied.
      }
      await File(raw.path).delete();
      return CapturedPhoto(path: destination, capturedAt: now);
    } catch (e) {
      error = 'Could not save photo. Please try again.';
      return null;
    } finally {
      isCapturing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
