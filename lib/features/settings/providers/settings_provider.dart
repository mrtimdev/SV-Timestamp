import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings settings = const AppSettings();
  ThemeMode get themeMode => settings.themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    settings = settings.copyWith(
      companyName: prefs.getString('companyName'),
      customNote: prefs.getString('customNote'),
      watermarkText: prefs.getString('watermarkText'),
      showDate: prefs.getBool('showDate'),
      showTime: prefs.getBool('showTime'),
      showGps: prefs.getBool('showGps'),
      showAddress: prefs.getBool('showAddress'),
      showDevice: prefs.getBool('showDevice'),
      showNote: prefs.getBool('showNote'),
      logoPath: prefs.getString('logoPath'),
      logoSize: prefs.getDouble('logoSize'),
      logoRadius: prefs.getDouble('logoRadius'),
      showLogo: prefs.getBool('showLogo'),
      showGpsAccuracy: prefs.getBool('showGpsAccuracy'),
      showStreet: prefs.getBool('showStreet'),
      showProvince: prefs.getBool('showProvince'),
      showCommune: prefs.getBool('showCommune'),
      showDistrict: prefs.getBool('showDistrict'),
      showVillage: prefs.getBool('showVillage'),
      showCity: prefs.getBool('showCity'),
      showCountry: prefs.getBool('showCountry'),
      fontSize: prefs.getDouble('fontSize'),
      backgroundOpacity: prefs.getDouble('backgroundOpacity'),
      borderRadius: prefs.getDouble('borderRadius'),
      watermarkScale: prefs.getDouble('watermarkScale'),
      watermarkZoom: prefs.getDouble('watermarkZoom')?.clamp(.25, 3.0),
      watermarkMargin: prefs.getDouble('watermarkMargin'),
      watermarkRowSpacing: prefs.getDouble('watermarkRowSpacing')?.clamp(0, 24),
      manualQuarterTurns: prefs.getInt('manualQuarterTurns'),
      normalizedX: prefs.getDouble('normalizedX'),
      normalizedY: prefs.getDouble('normalizedY'),
      template:
          WatermarkTemplate.values[prefs.getInt('watermarkTemplate') ??
              WatermarkTemplate.fieldReport.index],
      language: AppLanguage.values[prefs.getInt('language') ?? 0],
      position: OverlayPosition
          .values[prefs.getInt('position') ?? OverlayPosition.bottomLeft.index],
      themeMode:
          ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.light.index],
      cameraRatio: CameraRatio
          .values[prefs.getInt('cameraRatio') ?? CameraRatio.ratio3x4.index],
    );
    // Upgrade the previous default once; preserve explicitly selected templates
    // and all user text/logo choices. Later launches keep the chosen settings.
    if (!(prefs.getBool('fieldReportDefaultApplied') ?? false)) {
      if (!prefs.containsKey('watermarkTemplate') ||
          settings.template == WatermarkTemplate.classic) {
        await update(settings.withTemplate(WatermarkTemplate.fieldReport));
      }
      await prefs.setBool('fieldReportDefaultApplied', true);
    }
    if (!(prefs.getBool('watermarkFont10DefaultApplied') ?? false)) {
      // Move the previous 13pt default to 10pt once, keeping custom sizes.
      if (!prefs.containsKey('fontSize') || settings.fontSize == 13) {
        settings = settings.copyWith(fontSize: 10);
        await prefs.setDouble('fontSize', 10);
      }
      await prefs.setBool('watermarkFont10DefaultApplied', true);
    }
    if (!(prefs.getBool('watermarkMargin4DefaultApplied') ?? false)) {
      // Update the previous default once, preserving other margin choices.
      if (settings.watermarkMargin == 12) {
        settings = settings.copyWith(watermarkMargin: 4);
        await prefs.setDouble('watermarkMargin', 4);
      }
      await prefs.setBool('watermarkMargin4DefaultApplied', true);
    }
  }

  Future<void> updateNote(String value) => update(
    settings.copyWith(customNote: value, showNote: value.trim().isNotEmpty),
  );

  Future<void> update(AppSettings next) async {
    settings = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', next.companyName);
    await prefs.setString('customNote', next.customNote);
    await prefs.setString('watermarkText', next.watermarkText);
    await prefs.setBool('showDate', next.showDate);
    await prefs.setBool('showTime', next.showTime);
    await prefs.setBool('showGps', next.showGps);
    await prefs.setBool('showAddress', next.showAddress);
    await prefs.setBool('showDevice', next.showDevice);
    await prefs.setBool('showNote', next.showNote);
    if (next.logoPath != null) {
      await prefs.setString('logoPath', next.logoPath!);
    } else {
      await prefs.remove('logoPath');
    }
    await prefs.setDouble('logoSize', next.logoSize);
    await prefs.setDouble('logoRadius', next.logoRadius);
    await prefs.setBool('showLogo', next.showLogo);
    await prefs.setBool('showGpsAccuracy', next.showGpsAccuracy);
    await prefs.setBool('showStreet', next.showStreet);
    await prefs.setBool('showProvince', next.showProvince);
    await prefs.setBool('showCommune', next.showCommune);
    await prefs.setBool('showDistrict', next.showDistrict);
    await prefs.setBool('showVillage', next.showVillage);
    await prefs.setBool('showCity', next.showCity);
    await prefs.setBool('showCountry', next.showCountry);
    await prefs.setDouble('fontSize', next.fontSize);
    await prefs.setDouble('backgroundOpacity', next.backgroundOpacity);
    await prefs.setDouble('borderRadius', next.borderRadius);
    await prefs.setDouble('watermarkScale', next.watermarkScale);
    await prefs.setDouble('watermarkZoom', next.watermarkZoom);
    await prefs.setDouble('watermarkMargin', next.watermarkMargin);
    await prefs.setDouble('watermarkRowSpacing', next.watermarkRowSpacing);
    await prefs.setInt('manualQuarterTurns', next.manualQuarterTurns);
    await prefs.setDouble('normalizedX', next.normalizedX);
    await prefs.setDouble('normalizedY', next.normalizedY);
    await prefs.setInt('watermarkTemplate', next.template.index);
    await prefs.setInt('language', next.language.index);
    await prefs.setInt('position', next.position.index);
    await prefs.setInt('themeMode', next.themeMode.index);
    await prefs.setInt('cameraRatio', next.cameraRatio.index);
  }

  Future<void> pickLogo() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) await update(settings.copyWith(logoPath: image.path));
  }

  Future<void> useDefaultLogo() => update(settings.copyWith(clearLogo: true));
}
