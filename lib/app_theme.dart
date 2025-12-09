import 'package:flutter/material.dart';

// ValueNotifier to toggle between light and dark themes across the app.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    cardColor: Colors.white,
    dividerColor: Colors.black12,
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    cardColor: Colors.grey[850],
    dividerColor: Colors.white24,
  );
}

class ThemeColors {
  ThemeColors({
    required this.text,
    required this.subText,
    required this.card,
    required this.divider,
    required this.background,
    required this.isDark,
  });

  final Color text;
  final Color subText;
  final Color card;
  final Color divider;
  final Color background;
  final bool isDark;

  factory ThemeColors.from(BuildContext context) {
    final theme = Theme.of(context);
    return ThemeColors(
      text: theme.textTheme.bodyLarge?.color ?? Colors.white,
      subText: theme.textTheme.bodyMedium?.color ?? Colors.white70,
      card: theme.cardColor,
      divider: theme.dividerColor,
      background: theme.scaffoldBackgroundColor,
      isDark: theme.brightness == Brightness.dark,
    );
  }
}
