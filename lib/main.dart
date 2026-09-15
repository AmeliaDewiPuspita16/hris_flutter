import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session_storage.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth/auth_event.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib dipanggil sebelum runApp() supaya package:intl (dipakai internal
  // oleh Material DatePicker & month_picker_dialog) punya data locale
  // Indonesia. Tanpa ini -> LocaleDataException.
  await initializeDateFormatting('id_ID');

  runApp(
    MyApp(
      authRepository: AuthRepository(
        apiClient: ApiClient(),
        storage: SecureSessionStorage(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    // Repository disediakan ke seluruh pohon widget supaya LoginScreen bisa
    // membuat LoginBloc-nya sendiri saat layar itu dibuka.
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (_) =>
            AuthBloc(repository: authRepository)..add(const AuthStarted()),
        child: MaterialApp(
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
          home: const AuthGate(),
        ),
      ),
    );
  }
}
