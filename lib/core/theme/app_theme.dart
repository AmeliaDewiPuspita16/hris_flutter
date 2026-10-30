import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ThemeData terang & gelap, dibangun dari [AppPalette].
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.card,
      dividerColor: p.border,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
        primary: p.primary,
        surface: p.card,
        onSurface: p.text,
        surfaceContainerHigh: p.card,
        surfaceContainerHighest: p.neutralBg,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// Memaksa seluruh pohon widget dibangun ulang.
///
/// [AppColors] dibaca lewat getter global, bukan lewat InheritedWidget, jadi
/// Flutter tidak otomatis tahu widget mana yang perlu diperbarui saat mode
/// berganti. Navigasi dan state tetap utuh; hanya build() yang diulang.
void rebuildAllChildren(BuildContext context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
