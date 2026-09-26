import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sv_timestamp/features/camera/providers/camera_provider.dart';
import 'package:sv_timestamp/features/camera/widgets/field_report_overlay.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';
import 'package:sv_timestamp/features/settings/screens/settings_screen.dart';
import 'package:sv_timestamp/models/app_settings.dart';

void main() {
  testWidgets('settings select the default design and edit the shared note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider()
      ..settings = const AppSettings(
        language: AppLanguage.english,
        showNote: false,
      );
    final camera = CameraProvider(settings)..device = 'Test phone';
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<CameraProvider>.value(value: camera),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FieldReportOverlay), findsOneWidget);
    expect(find.text('SV Field Report (default)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Custom Note'), 300);
    final noteField = find.ancestor(
      of: find.text('Custom Note'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(noteField, 'Note changed in settings');
    await tester.pumpAndSettle();
    expect(settings.settings.customNote, 'Note changed in settings');
    expect(settings.settings.showNote, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('customNote'), 'Note changed in settings');
    await tester.pumpWidget(const SizedBox.shrink());
    camera.dispose();
    settings.dispose();
  });
}
