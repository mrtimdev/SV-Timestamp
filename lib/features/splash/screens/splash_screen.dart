import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(2.seconds, () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.camera);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dark,
            Color(0xFF172554),
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      child: Center(
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .28),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'SV Timestamp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Capture every detail',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 54),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(.92, .92),
                  curve: Curves.easeOutBack,
                ),
      ),
    ),
  );
}
