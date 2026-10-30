import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/data/est_project_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/est_form_worker.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/est_mandor.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/presentation/screens/project_form_screen.dart';

class _FakeRepository implements EstProjectRepository {
  final created = <Map<String, dynamic>>[];
  final updated = <(int, Map<String, dynamic>)>[];

  @override
  Future<List<EstMandor>> fetchMandors() async => const [];

  @override
  Future<List<EstFormWorker>> fetchFormWorkers({
    Map<String, String>? query,
  }) async =>
      [];

  @override
  Future<void> createProject(Map<String, dynamic> body) async =>
      created.add(body);

  @override
  Future<void> updateProject(int id, Map<String, dynamic> body) async =>
      updated.add((id, body));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repo;

  Future<void> pump(WidgetTester tester, {Map<String, dynamic>? project}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<EstProjectRepository>.value(
        value: repo,
        child: MaterialApp(home: ProjectFormScreen(project: project)),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byType(ElevatedButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  setUp(() => repo = _FakeRepository());

  testWidgets('submit kosong menampilkan validasi dan tidak memanggil API',
      (tester) async {
    await pump(tester);
    expect(find.text('Tambah Proyek'), findsOneWidget);

    await submit(tester);

    expect(find.text('Nama proyek wajib diisi'), findsOneWidget);
    expect(find.text('Lokasi wajib diisi'), findsOneWidget);
    expect(find.text('Budget jam wajib diisi'), findsOneWidget);
    expect(repo.created, isEmpty);
    expect(repo.updated, isEmpty);
  });

  testWidgets('mode edit mengisi field dan submit memanggil updateProject',
      (tester) async {
    await pump(tester, project: {
      'id': 9,
      'name': 'Menara',
      'location': 'Jakarta',
      'budget_hours': 5000,
      'start_date': '2026-11-01',
      'target_end_date': '2026-12-01',
    });
    expect(find.text('Edit Proyek'), findsOneWidget);
    expect(find.text('Menara'), findsOneWidget);

    await submit(tester);
    await tester.pump();

    expect(repo.created, isEmpty);
    expect(repo.updated, hasLength(1));
    expect(repo.updated.single.$1, 9);
    expect(repo.updated.single.$2, {
      'name': 'Menara',
      'location': 'Jakarta',
      'budget_hours': 5000,
      'start_date': '2026-11-01',
      'target_end_date': '2026-12-01',
    });
    await tester.pumpAndSettle();
  });
}
