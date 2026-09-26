import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';
import 'package:sv_timestamp/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default watermark uses the reference field-report design', () {
    const settings = AppSettings();
    expect(settings.template, WatermarkTemplate.fieldReport);
    expect(settings.showNote, isTrue);
    expect(settings.customNote, 'Site Inspection');
    expect(settings.showLogo && settings.showTime && settings.showDate, isTrue);
    expect(
      settings.showGps && settings.showAddress && settings.showDevice,
      isTrue,
    );
    expect(settings.position, OverlayPosition.bottomLeft);
    expect(settings.normalizedX, 0);
    expect(settings.normalizedY, 1);
  });

  test('old default upgrades once and preserves user text and logo', () async {
    SharedPreferences.setMockInitialValues({
      'watermarkTemplate': WatermarkTemplate.classic.index,
      'showNote': false,
      'customNote': 'Inspection at gate 3',
      'companyName': 'My company',
      'logoPath': '/custom/logo.png',
    });
    final provider = SettingsProvider();
    await provider.load();
    expect(provider.settings.template, WatermarkTemplate.fieldReport);
    expect(provider.settings.showNote, isTrue);
    expect(provider.settings.customNote, 'Inspection at gate 3');
    expect(provider.settings.companyName, 'My company');
    expect(provider.settings.logoPath, '/custom/logo.png');
    await provider.update(
      provider.settings.withTemplate(WatermarkTemplate.classic),
    );
    final reloaded = SettingsProvider();
    await reloaded.load();
    expect(reloaded.settings.template, WatermarkTemplate.classic);
  });

  test('explicit non-default templates survive the upgrade', () async {
    SharedPreferences.setMockInitialValues({
      'watermarkTemplate': WatermarkTemplate.minimal.index,
      'showNote': false,
    });
    final provider = SettingsProvider();
    await provider.load();
    expect(provider.settings.template, WatermarkTemplate.minimal);
    expect(provider.settings.showNote, isFalse);
  });

  test('notes persist and become visible from either editor', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SettingsProvider();
    await provider.load();
    await provider.updateNote('Gate inspection completed');
    final reloaded = SettingsProvider();
    await reloaded.load();
    expect(reloaded.settings.customNote, 'Gate inspection completed');
    expect(reloaded.settings.showNote, isTrue);
    await reloaded.updateNote('');
    expect(reloaded.settings.showNote, isFalse);
  });
}
