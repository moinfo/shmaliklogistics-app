import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode');
  themeNotifier.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleTheme() async {
  themeNotifier.value = themeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'theme_mode',
    themeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
  );
}
