import 'package:flutter/material.dart';

enum OverlayPosition { topLeft, topRight, bottomLeft, bottomRight }

enum AppLanguage { khmer, english }

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
    this.companyName = 'SV Technology',
    this.customNote = 'Site Inspection',
    this.watermarkText = '',
    this.logoPath,
    this.logoSize = 72,
    this.logoRadius = 12,
    this.position = OverlayPosition.bottomLeft,
    this.fontSize = 13,
    this.backgroundOpacity = .68,
    this.borderRadius = 18,
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.khmer,
  });

  final bool showDate, showTime, showGps, showAddress, showDevice, showNote;
  final bool showLogo;
  final bool showStreet, showProvince, showCommune, showDistrict;
  final bool showVillage, showCity, showCountry;
  final String companyName, customNote, watermarkText;
  final String? logoPath;
  final OverlayPosition position;
  final double fontSize, backgroundOpacity, borderRadius, logoSize, logoRadius;
  final ThemeMode themeMode;
  final AppLanguage language;

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
    ThemeMode? themeMode,
    AppLanguage? language,
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
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
  );
}
