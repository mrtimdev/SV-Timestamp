import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';
import 'package:sv_timestamp/main.dart';

void main() {
  testWidgets('shows SV Timestamp splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.load();

    await tester.pumpWidget(SVTimestampApp(settings: settings));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('SV Timestamp'), findsOneWidget);
    expect(find.text('Capture every detail'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
