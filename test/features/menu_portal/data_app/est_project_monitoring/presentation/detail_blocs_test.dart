import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/data/est_project_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/exec_project_full.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/project_worker.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/close_project_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/close_project_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/close_project_state.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/exec_project_detail_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/exec_project_detail_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/exec_project_detail_state.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/project_workers_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/project_workers_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/detail/project_workers_state.dart';

import '../../../../../fixtures/est_project_response.dart';

class _FakeRepository extends EstProjectRepository {
  _FakeRepository() : super(apiClient: ApiClient());

  Object? detailError;
  Object? workersError;
  Object? closeError;
  final closedIds = <int>[];

  @override
  Future<ExecProjectFullModel> fetchProjectDetail(int projectId) async {
    if (detailError != null) throw detailError!;
    return ExecProjectFullModel.fromJson(estExecProjectFullJson);
  }

  @override
  Future<List<ProjectWorkerModel>> fetchProjectWorkers(int projectId) async {
    if (workersError != null) throw workersError!;
    return [ProjectWorkerModel.fromJson(estProjectWorkerJson)];
  }

  @override
  Future<void> requestCloseProject(int projectId) async {
    closedIds.add(projectId);
    if (closeError != null) throw closeError!;
  }
}

void main() {
  late _FakeRepository repo;

  setUp(() => repo = _FakeRepository());

  group('ExecProjectDetailBloc', () {
    late ExecProjectDetailBloc bloc;
    setUp(() => bloc = ExecProjectDetailBloc(repository: repo));
    tearDown(() => bloc.close());

    test('load sukses -> Loading lalu Loaded', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecProjectDetailLoading>(),
          isA<ExecProjectDetailLoaded>()
              .having((s) => s.data.mandors.length, 'mandors', isNonZero),
        ]),
      );
      bloc.add(const LoadExecProjectDetail(1));
      await expectation;
    });

    test('ApiException -> Error membawa pesan server', () async {
      repo.detailError =
          const ApiException(ApiErrorKind.server, 'Proyek tidak ditemukan');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecProjectDetailLoading>(),
          isA<ExecProjectDetailError>()
              .having((s) => s.message, 'message', 'Proyek tidak ditemukan'),
        ]),
      );
      bloc.add(const LoadExecProjectDetail(1));
      await expectation;
    });

    test('galat lain -> pesan bawaan', () async {
      repo.detailError = StateError('x');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExecProjectDetailLoading>(),
          isA<ExecProjectDetailError>().having(
              (s) => s.message, 'message', 'Gagal memuat detail proyek'),
        ]),
      );
      bloc.add(const LoadExecProjectDetail(1));
      await expectation;
    });
  });

  group('ProjectWorkersBloc', () {
    late ProjectWorkersBloc bloc;
    setUp(() => bloc = ProjectWorkersBloc(repository: repo));
    tearDown(() => bloc.close());

    test('load sukses -> Loaded berisi daftar worker', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectWorkersLoading>(),
          isA<ProjectWorkersLoaded>()
              .having((s) => s.workers.length, 'workers', 1),
        ]),
      );
      bloc.add(const LoadProjectWorkers(1));
      await expectation;
    });

    test('ApiException -> Error membawa pesan server', () async {
      repo.workersError =
          const ApiException(ApiErrorKind.server, 'Tidak berwenang');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectWorkersLoading>(),
          isA<ProjectWorkersError>()
              .having((s) => s.message, 'message', 'Tidak berwenang'),
        ]),
      );
      bloc.add(const LoadProjectWorkers(1));
      await expectation;
    });

    test('galat lain -> pesan bawaan', () async {
      repo.workersError = StateError('x');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectWorkersLoading>(),
          isA<ProjectWorkersError>()
              .having((s) => s.message, 'message', 'Gagal memuat daftar tim'),
        ]),
      );
      bloc.add(const LoadProjectWorkers(1));
      await expectation;
    });
  });

  group('CloseProjectBloc', () {
    late CloseProjectBloc bloc;
    setUp(() => bloc = CloseProjectBloc(repository: repo));
    tearDown(() => bloc.close());

    test('submit sukses -> Loading lalu Success', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CloseProjectLoading>(),
          isA<CloseProjectSuccess>(),
        ]),
      );
      bloc.add(const SubmitCloseProject(7));
      await expectation;
      expect(repo.closedIds, [7]);
    });

    test('ApiException -> Failure membawa pesan server', () async {
      repo.closeError =
          const ApiException(ApiErrorKind.server, 'Sudah diminta');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CloseProjectLoading>(),
          isA<CloseProjectFailure>()
              .having((s) => s.message, 'message', 'Sudah diminta'),
        ]),
      );
      bloc.add(const SubmitCloseProject(7));
      await expectation;
    });

    test('galat lain -> pesan bawaan', () async {
      repo.closeError = StateError('x');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CloseProjectLoading>(),
          isA<CloseProjectFailure>()
              .having((s) => s.message, 'message', 'Gagal menutup proyek'),
        ]),
      );
      bloc.add(const SubmitCloseProject(7));
      await expectation;
    });
  });
}
