import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_router.dart';
import '../../../models/captured_photo.dart';
import '../../../core/utils/app_strings.dart';
import '../../settings/providers/settings_provider.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.photo});
  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(
      context.watch<SettingsProvider>().settings.language,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(strings.text('Photo preview', 'មើលរូបថត')),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Hero(
                tag: photo.path,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(File(photo.path), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Action(
                    icon: Icons.check_circle_rounded,
                    label: strings.text('Save', 'រក្សាទុក'),
                    color: AppColors.success,
                    onTap: () => Navigator.popUntil(
                      context,
                      ModalRoute.withName(AppRoutes.camera),
                    ),
                  ),
                  _Action(
                    icon: Icons.share_rounded,
                    label: strings.text('Share', 'ចែករំលែក'),
                    onTap: () => SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(photo.path)],
                        text: 'Captured with SV Timestamp',
                      ),
                    ),
                  ),
                  _Action(
                    icon: Icons.delete_outline_rounded,
                    label: strings.text('Delete', 'លុប'),
                    color: Colors.redAccent,
                    onTap: () async {
                      await File(photo.path).delete();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _Action(
                    icon: Icons.camera_alt_outlined,
                    label: strings.text('Retake', 'ថតឡើងវិញ'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
