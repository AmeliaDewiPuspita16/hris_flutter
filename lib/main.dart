import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib dipanggil sebelum runApp() supaya package:intl (dipakai internal
  // oleh Material DatePicker & month_picker_dialog) punya data locale
  // Indonesia. Tanpa ini -> LocaleDataException.
  await initializeDateFormatting('id_ID');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRIS Mobile',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        fontFamily: 'Poppins',
      ),
      home: const LoginScreen(),
    );
  }
}