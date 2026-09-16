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
import 'features/shared/data/department_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib dipanggil sebelum runApp() supaya package:intl (dipakai internal
  // oleh Material DatePicker & month_picker_dialog) punya data locale
  // Indonesia. Tanpa ini -> LocaleDataException.
  await initializeDateFormatting('id_ID');

  // Satu ApiClient dipakai bersama oleh semua repository, supaya token yang
  // dipasang AuthRepository setelah login otomatis ikut terpakai saat
  // DepartmentRepository (dan repository lain nanti) memanggil endpoint
  // yang perlu Authorization header.
  final apiClient = ApiClient();

  runApp(
    MyApp(
      authRepository: AuthRepository(
        apiClient: apiClient,
        storage: SecureSessionStorage(),
      ),
      departmentRepository: DepartmentRepository(apiClient: apiClient),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    required this.authRepository,
    DepartmentRepository? departmentRepository,
  }) : departmentRepository =
            departmentRepository ?? DepartmentRepository(apiClient: ApiClient());

  final AuthRepository authRepository;
  final DepartmentRepository departmentRepository;

  @override
  Widget build(BuildContext context) {
    // Repository disediakan ke seluruh pohon widget supaya LoginScreen bisa
    // membuat LoginBloc-nya sendiri saat layar itu dibuka, dan supaya layar
    // atau sheet manapun (mis. form pengumuman) bisa mengambil
    // DepartmentRepository lewat context tanpa perlu diteruskan manual.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: departmentRepository),
      ],
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