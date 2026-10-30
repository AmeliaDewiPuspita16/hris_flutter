import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/data/est_project_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/add_workers/add_workers_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/add_workers/add_workers_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/add_workers/add_workers_state.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/substitute/substitute_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/substitute/substitute_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/substitute/substitute_state.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/worker_transfer/worker_transfer_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/worker_transfer/worker_transfer_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/bloc/worker_transfer/worker_transfer_state.dart';

class _FakeRepository extends EstProjectRepository {
  _FakeRepository() : super(apiClient: ApiClient());

  Object? error;
  Map<String, dynamic> reply = {};
  final calls = <String>[];
  Map<String, dynamic>? substituteBody;

  @override
  Future<Map<String, dynamic>> assignWorkers(
    int projectId,
    List<int> workerIds,
  ) async {
    calls.add('assign $projectId $workerIds');
    if (error != null) throw error!;
    return reply;
  }

  @override
  Future<Map<String, dynamic>> transferWorkers(
    int projectId, {
    required int targetProjectId,
    required List<int> workerIds,
    String? reason,
  }) async {
    calls.add('transfer $projectId $targetProjectId $workerIds $reason');
    if (error != null) throw error!;
    return reply;
  }

  @override
  Future<void> assignSubstitute(
    int projectId,
    Map<String, dynamic> body,
  ) async {
    substituteBody = body;
    if (error != null) throw error!;
  }

  @override
  Future<void> endSubstitute(int projectId, int assignmentId) async {
    calls.add('end $projectId $assignmentId');
    if (error != null) throw error!;
  }
}

void main() {
  late _FakeRepository repo;

  setUp(() => repo = _FakeRepository());

  group('AddWorkersBloc', () {
    late AddWorkersBloc bloc;
    setUp(() => bloc = AddWorkersBloc(repository: repo));
    tearDown(() => bloc.close());

    test('sukses membawa message server', () async {
      repo.reply = {'message': '2 worker ditambahkan'};
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AddWorkersLoading>(),
          isA<AddWorkersSuccess>()
              .having((s) => s.message, 'message', '2 worker ditambahkan'),
        ]),
      );
      bloc.add(const SubmitAddWorkers(projectId: 3, workerIds: [1, 2]));
      await expectation;
      expect(repo.calls, ['assign 3 [1, 2]']);
    });

    test('tanpa message -> teks bawaan DW', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AddWorkersLoading>(),
          isA<AddWorkersSuccess>().having(
              (s) => s.message, 'message', 'Worker berhasil ditambahkan'),
        ]),
      );
      bloc.add(const SubmitAddWorkers(projectId: 3, workerIds: [1]));
      await expectation;
    });

    test('ApiException.badRequest menampilkan pesannya', () async {
      repo.error = const ApiException.badRequest('Nama wajib diisi.');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AddWorkersLoading>(),
          isA<AddWorkersFailure>()
              .having((s) => s.message, 'message', 'Nama wajib diisi.'),
        ]),
      );
      bloc.add(const SubmitAddWorkers(projectId: 3, workerIds: [1]));
      await expectation;
    });

    test('galat lain -> pesan bawaan', () async {
      repo.error = StateError('x');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AddWorkersLoading>(),
          isA<AddWorkersFailure>()
              .having((s) => s.message, 'message', 'Gagal menambahkan worker'),
        ]),
      );
      bloc.add(const SubmitAddWorkers(projectId: 3, workerIds: [1]));
      await expectation;
    });
  });

  group('WorkerTransferBloc', () {
    late WorkerTransferBloc bloc;
    setUp(() => bloc = WorkerTransferBloc(repository: repo));
    tearDown(() => bloc.close());

    test('sukses membawa message server dan meneruskan argumen', () async {
      repo.reply = {'message': 'Dipindahkan'};
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkerTransferLoading>(),
          isA<WorkerTransferSuccess>()
              .having((s) => s.message, 'message', 'Dipindahkan'),
        ]),
      );
      bloc.add(const SubmitWorkerTransfer(
        fromProjectId: 1,
        workerIds: [9],
        targetProjectId: 2,
        reason: 'butuh tenaga',
      ));
      await expectation;
      expect(repo.calls, ['transfer 1 2 [9] butuh tenaga']);
    });

    test('tanpa message -> teks bawaan DW', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkerTransferLoading>(),
          isA<WorkerTransferSuccess>().having(
              (s) => s.message, 'message', 'Worker berhasil dipindahkan'),
        ]),
      );
      bloc.add(const SubmitWorkerTransfer(
        fromProjectId: 1,
        workerIds: [9],
        targetProjectId: 2,
      ));
      await expectation;
    });

    test('ApiException.badRequest menampilkan pesannya', () async {
      repo.error = const ApiException.badRequest('Nama wajib diisi.');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkerTransferLoading>(),
          isA<WorkerTransferFailure>()
              .having((s) => s.message, 'message', 'Nama wajib diisi.'),
        ]),
      );
      bloc.add(const SubmitWorkerTransfer(
        fromProjectId: 1,
        workerIds: [9],
        targetProjectId: 2,
      ));
      await expectation;
    });
  });

  group('SubstituteBloc', () {
    late SubstituteBloc bloc;
    setUp(() => bloc = SubstituteBloc(repository: repo));
    tearDown(() => bloc.close());

    test('assign mandor memakai user_id dan alasan kosong', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SubstituteLoading>(),
          isA<SubstituteSuccess>().having(
              (s) => s.message, 'message', 'Pengganti berhasil ditugaskan'),
        ]),
      );
      bloc.add(const AssignSubstitute(
        projectId: 1,
        role: 'mandor',
        substituteFor: 5,
        replacementId: 6,
      ));
      await expectation;
      expect(repo.substituteBody, {
        'role': 'mandor',
        'substitute_for': 5,
        'substitute_reason': '',
        'user_id': 6,
      });
    });

    test('assign worker memakai worker_id', () async {
      bloc.add(const AssignSubstitute(
        projectId: 1,
        role: 'worker',
        substituteFor: 5,
        replacementId: 6,
        reason: 'sakit',
      ));
      await bloc.stream.firstWhere((s) => s is SubstituteSuccess);
      expect(repo.substituteBody, {
        'role': 'worker',
        'substitute_for': 5,
        'substitute_reason': 'sakit',
        'worker_id': 6,
      });
    });

    test('end sukses', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SubstituteLoading>(),
          isA<SubstituteSuccess>().having(
              (s) => s.message, 'message', 'Substitusi berhasil diakhiri'),
        ]),
      );
      bloc.add(const EndSubstitute(projectId: 1, assignmentId: 8));
      await expectation;
      expect(repo.calls, ['end 1 8']);
    });

    test('ApiException.badRequest menampilkan pesannya', () async {
      repo.error = const ApiException.badRequest('Nama wajib diisi.');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SubstituteLoading>(),
          isA<SubstituteFailure>()
              .having((s) => s.message, 'message', 'Nama wajib diisi.'),
        ]),
      );
      bloc.add(const AssignSubstitute(
        projectId: 1,
        role: 'mandor',
        substituteFor: 5,
        replacementId: 6,
      ));
      await expectation;
    });

    test('galat lain pada end -> pesan bawaan', () async {
      repo.error = StateError('x');
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SubstituteLoading>(),
          isA<SubstituteFailure>().having(
              (s) => s.message, 'message', 'Gagal mengakhiri substitusi'),
        ]),
      );
      bloc.add(const EndSubstitute(projectId: 1, assignmentId: 8));
      await expectation;
    });
  });
}
