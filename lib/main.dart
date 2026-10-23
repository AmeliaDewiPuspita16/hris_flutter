import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_colors.dart';
import 'features/absensi/data/absensi_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session_storage.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth/auth_event.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/home/data/announcement_repository.dart';
import 'features/home/data/approvals_waiting_repository.dart';
import 'features/menu_portal/data_app/indent_vehicle/data/indent_vehicle_repository.dart';
import 'features/menu_portal/onlineapps/procurement/data/procurement_repository.dart';
import 'features/menu_portal/onlineapps/work_order/est_request/data/est_request_repository.dart';
import 'features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'features/overtime_request/data/overtime_repository.dart';
import 'features/pengajuan/data/pengajuan_repository.dart';
import 'features/profil/data/profil_repository.dart';
import 'features/shared/data/department_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib diinisialisasi sebelum runApp() supaya plugin Firebase lain
  // (messaging, analytics, dll.) bisa dipakai di seluruh app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Didaftarkan sebelum runApp() supaya pesan FCM yang datang saat app
  // di-background/terminated tetap tertangani. Harus merujuk top-level
  // function (lih. notification_service.dart), bukan closure/method.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Wajib dipanggil sebelum runApp() supaya package:intl (dipakai internal
  // oleh Material DatePicker & month_picker_dialog) punya data locale
  // Inggris. Tanpa ini -> LocaleDataException.
  await initializeDateFormatting('en_US');

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
      announcementRepository: AnnouncementRepository(apiClient: apiClient),
      procurementRepository: ProcurementRepository(apiClient: apiClient),
      itRequestRepository: ItRequestRepository(apiClient: apiClient),
      estRequestRepository: EstRequestRepository(apiClient: apiClient),
      indentVehicleRepository: IndentVehicleRepository(apiClient: apiClient),
      profilRepository: ProfilRepository(apiClient: apiClient),
      absensiRepository: AbsensiRepository(apiClient: apiClient),
      pengajuanRepository: PengajuanRepository(apiClient: apiClient),
      overtimeRepository: OvertimeRepository(apiClient: apiClient),
      approvalsWaitingRepository:
          ApprovalsWaitingRepository(apiClient: apiClient),
    ),
  );

  // Dipanggil setelah runApp(), bukan di-await di sini, supaya first frame
  // tetap tampil walau Future-nya menggantung. Di Chrome (flutter run -d
  // chrome), window tidak otomatis fokus, dan Notification.requestPermission()
  // browser bisa tidak pernah resolve kalau tab-nya tidak fokus -- kalau ini
  // di-await sebelum runApp(), seluruh app macet di splash screen.
  unawaited(NotificationService().init());
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    required this.authRepository,
    DepartmentRepository? departmentRepository,
    AnnouncementRepository? announcementRepository,
    ProcurementRepository? procurementRepository,
    ItRequestRepository? itRequestRepository,
    EstRequestRepository? estRequestRepository,
    IndentVehicleRepository? indentVehicleRepository,
    ProfilRepository? profilRepository,
    AbsensiRepository? absensiRepository,
    PengajuanRepository? pengajuanRepository,
    OvertimeRepository? overtimeRepository,
    ApprovalsWaitingRepository? approvalsWaitingRepository,
  })  : departmentRepository = departmentRepository ??
            DepartmentRepository(apiClient: ApiClient()),
        announcementRepository = announcementRepository ??
            AnnouncementRepository(apiClient: ApiClient()),
        procurementRepository = procurementRepository ??
            ProcurementRepository(apiClient: ApiClient()),
        itRequestRepository =
            itRequestRepository ?? ItRequestRepository(apiClient: ApiClient()),
        estRequestRepository = estRequestRepository ??
            EstRequestRepository(apiClient: ApiClient()),
        indentVehicleRepository = indentVehicleRepository ??
            IndentVehicleRepository(apiClient: ApiClient()),
        profilRepository =
            profilRepository ?? ProfilRepository(apiClient: ApiClient()),
        absensiRepository =
            absensiRepository ?? AbsensiRepository(apiClient: ApiClient()),
        pengajuanRepository =
            pengajuanRepository ?? PengajuanRepository(apiClient: ApiClient()),
        overtimeRepository =
            overtimeRepository ?? OvertimeRepository(apiClient: ApiClient()),
        approvalsWaitingRepository = approvalsWaitingRepository ??
            ApprovalsWaitingRepository(apiClient: ApiClient());

  final AuthRepository authRepository;
  final DepartmentRepository departmentRepository;
  final AnnouncementRepository announcementRepository;
  final ProcurementRepository procurementRepository;
  final ItRequestRepository itRequestRepository;
  final EstRequestRepository estRequestRepository;
  final IndentVehicleRepository indentVehicleRepository;
  final ProfilRepository profilRepository;
  final AbsensiRepository absensiRepository;
  final PengajuanRepository pengajuanRepository;
  final OvertimeRepository overtimeRepository;
  final ApprovalsWaitingRepository approvalsWaitingRepository;

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
        RepositoryProvider.value(value: announcementRepository),
        RepositoryProvider.value(value: procurementRepository),
        RepositoryProvider.value(value: itRequestRepository),
        RepositoryProvider.value(value: estRequestRepository),
        RepositoryProvider.value(value: indentVehicleRepository),
        RepositoryProvider.value(value: profilRepository),
        RepositoryProvider.value(value: absensiRepository),
        RepositoryProvider.value(value: pengajuanRepository),
        RepositoryProvider.value(value: overtimeRepository),
        RepositoryProvider.value(value: approvalsWaitingRepository),
      ],
      child: BlocProvider(
        create: (_) =>
            AuthBloc(repository: authRepository)..add(const AuthStarted()),
        child: MaterialApp(
          title: 'BIIE Portal',
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
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
