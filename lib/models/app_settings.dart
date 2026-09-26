import 'package:flutter/material.dart';

// Keep new values appended so existing persisted enum indexes remain valid.
enum OverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  bottomCenter,
}

enum AppLanguage { khmer, english }

enum WatermarkTemplate {
  classic,
  gpsAddress,
  siteInspection,
  minimal,
  business,
  custom,
  fieldReport,
}

enum CameraRatio {
  ratio3x4(3, 4, '3:4'),
  ratio9x16(9, 16, '9:16'),
  ratio1x1(1, 1, '1:1'),
  full(0, 0, 'Full');

  const CameraRatio(this.w, this.h, this.label);
  final int w, h;
  final String label;
}

class AppSettings {
  const AppSettings({
    this.showDate = true,
    this.showTime = true,
    this.showGps = true,
    this.showAddress = true,
    this.showStreet = true,
    this.showProvince = true,
    this.showCommune = true,
    this.showDistrict = true,
    this.showVillage = true,
    this.showCity = true,
    this.showCountry = true,
    this.showDevice = true,
    this.showNote = true,
    this.showLogo = true,
    this.showGpsAccuracy = false,
    this.companyName = 'SV Timestamp',
    this.customNote = 'Site Inspection',
    this.watermarkText = '',
    this.logoPath,
    this.logoSize = 140,
    this.logoRadius = 0,
    this.position = OverlayPosition.bottomLeft,
    this.fontSize = 13,
    this.backgroundOpacity = .68,
    this.borderRadius = 18,
    this.watermarkScale = 1,
    this.watermarkZoom = 1,
    this.watermarkMargin = 12,
    this.manualQuarterTurns = 0,
    this.normalizedX = 0,
    this.normalizedY = 1,
    this.template = WatermarkTemplate.fieldReport,
    this.themeMode = ThemeMode.light,
    this.language = AppLanguage.khmer,
    this.cameraRatio = CameraRatio.ratio3x4,
  });

  final bool showDate, showTime, showGps, showAddress, showDevice, showNote;
  final bool showLogo;
  final bool showGpsAccuracy;
  final bool showStreet, showProvince, showCommune, showDistrict;
  final bool showVillage, showCity, showCountry;
  final String companyName, customNote, watermarkText;
  final String? logoPath;
  final OverlayPosition position;
  final double fontSize, backgroundOpacity, borderRadius, logoSize, logoRadius;
  final double watermarkScale, watermarkMargin, normalizedX, normalizedY;
  final double watermarkZoom;
  final int manualQuarterTurns;
  final WatermarkTemplate template;
  final ThemeMode themeMode;
  final AppLanguage language;
  final CameraRatio cameraRatio;

  AppSettings withTemplate(WatermarkTemplate value) => switch (value) {
    WatermarkTemplate.fieldReport => copyWith(
      template: value,
      showLogo: true,
      showDate: true,
      showTime: true,
      showGps: true,
      showAddress: true,
      showDevice: true,
      showNote: true,
      showGpsAccuracy: false,
      logoSize: 140,
      logoRadius: 0,
      position: OverlayPosition.bottomLeft,
      normalizedX: 0,
      normalizedY: 1,
    ),
    WatermarkTemplate.classic => copyWith(
      template: value,
      showLogo: true,
      showGps: true,
      showAddress: true,
      showNote: false,
    ),
    WatermarkTemplate.gpsAddress => copyWith(
      template: value,
      showLogo: false,
      showGps: true,
      showAddress: true,
      showGpsAccuracy: true,
      showNote: false,
    ),
    WatermarkTemplate.siteInspection => copyWith(
      template: value,
      showLogo: true,
      showGps: true,
      showAddress: true,
      showNote: true,
    ),
    WatermarkTemplate.minimal => copyWith(
      template: value,
      showLogo: false,
      showGps: false,
      showAddress: false,
      showDevice: false,
      showNote: false,
    ),
    WatermarkTemplate.business => copyWith(
      template: value,
      showLogo: true,
      showGps: false,
      showAddress: true,
      showDevice: false,
      showNote: true,
    ),
    WatermarkTemplate.custom => copyWith(template: value),
  };

  AppSettings copyWith({
    bool? showDate,
    bool? showTime,
    bool? showGps,
    bool? showAddress,
    bool? showStreet,
    bool? showProvince,
    bool? showCommune,
    bool? showDistrict,
    bool? showVillage,
    bool? showCity,
    bool? showCountry,
    bool? showDevice,
    bool? showNote,
    bool? showLogo,
    bool? showGpsAccuracy,
    String? companyName,
    String? customNote,
    String? watermarkText,
    String? logoPath,
    bool clearLogo = false,
    double? logoSize,
    double? logoRadius,
    OverlayPosition? position,
    double? fontSize,
    double? backgroundOpacity,
    double? borderRadius,
    double? watermarkScale,
    double? watermarkZoom,
    double? watermarkMargin,
    int? manualQuarterTurns,
    double? normalizedX,
    double? normalizedY,
    WatermarkTemplate? template,
    ThemeMode? themeMode,
    AppLanguage? language,
    CameraRatio? cameraRatio,
  }) => AppSettings(
    showDate: showDate ?? this.showDate,
    showTime: showTime ?? this.showTime,
    showGps: showGps ?? this.showGps,
    showAddress: showAddress ?? this.showAddress,
    showStreet: showStreet ?? this.showStreet,
    showProvince: showProvince ?? this.showProvince,
    showCommune: showCommune ?? this.showCommune,
    showDistrict: showDistrict ?? this.showDistrict,
    showVillage: showVillage ?? this.showVillage,
    showCity: showCity ?? this.showCity,
    showCountry: showCountry ?? this.showCountry,
    showDevice: showDevice ?? this.showDevice,
    showNote: showNote ?? this.showNote,
    showLogo: showLogo ?? this.showLogo,
    showGpsAccuracy: showGpsAccuracy ?? this.showGpsAccuracy,
    companyName: companyName ?? this.companyName,
    customNote: customNote ?? this.customNote,
    watermarkText: watermarkText ?? this.watermarkText,
    logoPath: clearLogo ? null : logoPath ?? this.logoPath,
    logoSize: logoSize ?? this.logoSize,
    logoRadius: logoRadius ?? this.logoRadius,
    position: position ?? this.position,
    fontSize: fontSize ?? this.fontSize,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    borderRadius: borderRadius ?? this.borderRadius,
    watermarkScale: watermarkScale ?? this.watermarkScale,
    watermarkZoom: watermarkZoom ?? this.watermarkZoom,
    watermarkMargin: watermarkMargin ?? this.watermarkMargin,
    manualQuarterTurns: manualQuarterTurns ?? this.manualQuarterTurns,
    normalizedX: normalizedX ?? this.normalizedX,
    normalizedY: normalizedY ?? this.normalizedY,
    template: template ?? this.template,
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    cameraRatio: cameraRatio ?? this.cameraRatio,
  );
}
