import 'package:flutter/material.dart';
import '../app_theme.dart';

class PlaceholderSection extends StatelessWidget {
  const PlaceholderSection({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 48, color: Colors.tealAccent),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: palette.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: palette.subText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
