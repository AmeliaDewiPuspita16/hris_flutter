import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Menyimpan pilihan mode terang/gelap, dan menyetel [AppColors] sebelum UI
/// dibangun ulang.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeMode initial = ThemeMode.light, SharedPreferences? prefs})
      : _prefs = prefs,
        super(initial);

  static const _key = 'theme_dark_mode';

  final SharedPreferences? _prefs;

  /// Baca pilihan tersimpan. Panggil di main() sebelum runApp() supaya frame
  /// pertama langsung memakai mode yang benar (tanpa kedip terang->gelap).
  static Future<ThemeCubit> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_key) ?? false;
    AppColors.setDark(dark);
    return ThemeCubit(
      initial: dark ? ThemeMode.dark : ThemeMode.light,
      prefs: prefs,
    );
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> setDark(bool value) async {
    AppColors.setDark(value);
    emit(value ? ThemeMode.dark : ThemeMode.light);
    await _prefs?.setBool(_key, value);
  }
}
