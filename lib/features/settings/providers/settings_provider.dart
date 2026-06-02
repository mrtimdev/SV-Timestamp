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
      language: AppLanguage.values[prefs.getInt('language') ?? 0],
      position: OverlayPosition.values[prefs.getInt('position') ?? 3],
      themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? 0],
    );
  }

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
    await prefs.setInt('language', next.language.index);
    await prefs.setInt('position', next.position.index);
    await prefs.setInt('themeMode', next.themeMode.index);
  }

  Future<void> pickLogo() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) await update(settings.copyWith(logoPath: image.path));
  }

  Future<void> useDefaultLogo() => update(settings.copyWith(clearLogo: true));
}
