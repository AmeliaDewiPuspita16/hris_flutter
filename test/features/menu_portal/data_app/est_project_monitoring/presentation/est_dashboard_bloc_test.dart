import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/data/est_project_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/executive_dashboard.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/dashboard/executive_dashboard_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/dashboard/executive_dashboard_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/dashboard/executive_dashboard_state.dart';

import '../../../../../fixtures/est_project_response.dart';

class _FakeRepository extends EstProjectRepository {
  _FakeRepository() : super(apiClient: ApiClient());

  Object? loadError;
  Object? openError;
  Object? closeError;
  final calls = <String>[];

  @override
  Future<ExecutiveDashboardModel> fetchExecutiveDashboard() async {
    if (loadError != null) throw loadError!;
    return ExecutiveDashboardModel.fromJson(estExecutiveDashboardJson);
  }

  @override
  Future<void> openSession(int projectId) async {
    calls.add('open $projectId');
    if (openError != null) throw openError!;
  }

  @override
  Future<void> closeSession(
    int projectId, {
    required String description,
    required bool autoClockOut,
    List<String> photoPaths = const [],
  }) async {
    calls.add('close $projectId $description $autoClockOut $photoPaths');
    if (closeError != null) throw closeError!;
  }
}

void main() {
  late _FakeRepository repo;
  late ExecutiveDashboardBloc bloc;

  setUp(() {
    repo = _FakeRepository();
    bloc = ExecutiveDashboardBloc(repository: repo);
  });

  tearDown(() => bloc.close());

  test('load -> Loading lalu Loaded', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ExecutiveDashboardLoading>(),
        isA<ExecutiveDashboardLoaded>()
            .having((s) => s.data.projects.length, 'projects', 2),
      ]),
    );
    bloc.add(const LoadExecutiveDashboard());
    await expectation;
  });

  test('load unauthorized -> NoAccess', () async {
    repo.loadError = const ApiException.unauthorized();
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ExecutiveDashboardLoading>(),
        isA<ExecutiveDashboardNoAccess>(),
      ]),
    );
    bloc.add(const LoadExecutiveDashboard());
    await expectation;
  });

  test('load server error -> Error dengan pesan', () async {
    repo.loadError = const ApiException.server('x');
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ExecutiveDashboardLoading>(),
        isA<ExecutiveDashboardError>().having((s) => s.message, 'message', 'x'),
      ]),
    );
    bloc.add(const LoadExecutiveDashboard());
    await expectation;
  });

  test('galat tak terduga -> pesan bawaan', () async {
    repo.loadError = StateError('boom');
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ExecutiveDashboardLoading>(),
        isA<ExecutiveDashboardError>()
            .having((s) => s.message, 'message', 'Gagal memuat data dashboard'),
      ]),
    );
    bloc.add(const LoadExecutiveDashboard());
    await expectation;
  });

  group('sesi', () {
    setUp(() async {
      bloc.add(const LoadExecutiveDashboard());
      await bloc.stream.firstWhere((s) => s is ExecutiveDashboardLoaded);
    });

    test('buka sesi -> SessionLoading lalu SessionSuccess', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecutiveSessionLoading>(),
          isA<ExecutiveSessionSuccess>()
              .having((s) => s.message, 'message', 'Sesi berhasil dibuka'),
        ]),
      );
      bloc.add(const OpenExecutiveSession(7));
      await expectation;
      expect(repo.calls, ['open 7']);
    });

    test('buka sesi gagal -> SessionError menyimpan data', () async {
      repo.openError = const ApiException.badRequest('ditolak');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecutiveSessionLoading>(),
          isA<ExecutiveSessionError>()
              .having((s) => s.message, 'message', 'ditolak'),
        ]),
      );
      bloc.add(const OpenExecutiveSession(7));
      await expectation;
    });

    test('tutup sesi berhasil meneruskan argumen ke repository', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecutiveSessionLoading>(),
          isA<ExecutiveSessionSuccess>()
              .having((s) => s.message, 'message', 'Sesi berhasil ditutup'),
        ]),
      );
      bloc.add(const CloseExecutiveSession(
        7,
        'Pengecoran selesai',
        autoClockOut: true,
        photoPaths: ['/a.jpg'],
      ));
      await expectation;
      expect(repo.calls, ['close 7 Pengecoran selesai true [/a.jpg]']);
    });

    test('tutup sesi gagal mempertahankan currentData', () async {
      final loaded = bloc.state as ExecutiveDashboardLoaded;
      repo.closeError = StateError('boom');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecutiveSessionLoading>(),
          isA<ExecutiveSessionError>()
              .having((s) => s.message, 'message', 'Gagal menutup sesi')
              .having((s) => identical(s.currentData, loaded.data),
                  'currentData', true),
        ]),
      );
      bloc.add(const CloseExecutiveSession(7, 'deskripsi panjang'));
      await expectation;
    });
  });
}
