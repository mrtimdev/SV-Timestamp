import 'package:flutter/material.dart';
import 'glass_panel.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.backgroundColor,
    this.borderColor,
    this.tooltip,
    this.size = 48,
    this.iconSize = 22,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final button = GlassPanel(
      padding: EdgeInsets.zero,
      radius: size / 2.4,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2.4),
            onTap: onPressed,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: color, size: iconSize),
                  if (badge != null)
                    Positioned(top: -2, right: -2, child: badge!),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
