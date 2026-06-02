import 'package:flutter/material.dart';

import '../../features/camera/screens/camera_screen.dart';
import '../../features/camera/screens/preview_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../models/captured_photo.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const camera = '/camera';
  static const preview = '/preview';
  static const gallery = '/gallery';
  static const settings = '/settings';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.camera => const CameraScreen(),
      AppRoutes.preview => PreviewScreen(
        photo: settings.arguments! as CapturedPhoto,
      ),
      AppRoutes.gallery => const GalleryScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => const SplashScreen(),
    };
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
