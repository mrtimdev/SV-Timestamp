import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/camera/providers/camera_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'models/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  runApp(SVTimestampApp(settings: settings));
}

class SVTimestampApp extends StatelessWidget {
  const SVTimestampApp({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => CameraProvider(settings)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'SV Timestamp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: Locale(
            settings.settings.language == AppLanguage.khmer ? 'km' : 'en',
          ),
          supportedLocales: const [Locale('km'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
