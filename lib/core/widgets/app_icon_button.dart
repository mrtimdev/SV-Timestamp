import 'package:flutter/material.dart';
import 'glass_panel.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => GlassPanel(
    padding: EdgeInsets.zero,
    radius: 18,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      tooltip: tooltip,
    ),
  );
}
