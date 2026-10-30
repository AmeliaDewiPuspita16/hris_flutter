import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/est_available_worker.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/est_mandor.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/exec_project_full.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/executive_dashboard.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/domain/project_worker.dart';

import '../../../../../fixtures/est_project_response.dart';

void main() {
  group('ExecutiveDashboardModel', () {
    test('parse summary dan daftar project', () {
      final m = ExecutiveDashboardModel.fromJson(estExecutiveDashboardJson);
      expect(m.summary.activeProjects, 2);
      expect(m.summary.totalWorkerToday, 30);
      expect(m.summary.hoursUsedPct, 42);
      expect(m.projects.length,
          (estExecutiveDashboardJson['projects'] as List).length);
    });

    test('ExecutiveProjectModel memetakan semua field', () {
      final p = ExecutiveProjectModel.fromJson(estExecutiveProjectJson);
      expect(p.id, 1);
      expect(p.name, 'Proyek Alpha');
      expect(p.jobNumber, 'JOB-001');
      expect(p.location, 'Batam');
      expect(p.budgetHours, 1500);
      expect(p.usedHours, 750.5);
      expect(p.remainingHours, 749.5);
      expect(p.progressPercent, 50);
      expect(p.status, 'active');
      expect(p.startDate, '2026-01-01');
      expect(p.targetEndDate, '2026-12-31');
      expect(p.sessionStatus, 'open');
      expect(p.isOpen, isTrue);
      expect(p.sessionId, 9);
      expect(p.sessionOpenedAt, '2026-10-30 07:00:00');
      expect(p.notClockedOut, 1);
      expect(p.notClockedOutList.single.name, 'Budi');
      expect(p.notClockedOutList.single.clockIn, '07:30');
      expect(p.progress, closeTo(0.50033, 0.0001));
      expect(p.usedHoursLabel, '750.5');
      expect(p.budgetHoursLabel, '1.5k');
    });

    test('field opsional hilang memakai default DW', () {
      final p = ExecutiveProjectModel.fromJson(estExecutiveProjectMinimalJson);
      expect(p.jobNumber, isNull);
      expect(p.sessionStatus, 'no_session');
      expect(p.isOpen, isFalse);
      expect(p.sessionId, isNull);
      expect(p.sessionOpenedAt, isNull);
      expect(p.notClockedOut, 0);
      expect(p.notClockedOutList, isEmpty);
      expect(p.progress, 0.0);
    });
  });

  group('ExecProjectFullModel', () {
    test('parse dari amplop data', () {
      final m = ExecProjectFullModel.fromJson(estExecProjectFullJson);
      expect(m.id, 1);
      expect(m.avgHoursPerDay, 12.5);
      expect(m.estimatedDaysLeft, 20);
      expect(m.closedAt, '2026-12-31');
      final mandor = m.mandors.single;
      expect(mandor.id, 5);
      expect(mandor.isSubstitute, isTrue);
      expect(mandor.assignmentId, 33);
      expect(mandor.substituteFor?.name, 'Joko Widodo');
      expect(mandor.initials, 'SA');
    });

    test('tanpa amplop data dan field opsional memakai default', () {
      final m = ExecProjectFullModel.fromJson({'id': 3});
      expect(m.mandors, isEmpty);
      expect(m.avgHoursPerDay, 0.0);
      expect(m.estimatedDaysLeft, 0);
      expect(m.closedAt, isNull);
    });

    test('MandorModel default', () {
      final m = MandorModel.fromJson({'id': 1});
      expect(m.name, '-');
      expect(m.isSubstitute, isFalse);
      expect(m.substituteFor, isNull);
      expect(m.assignmentId, isNull);
    });
  });

  group('ProjectWorkerModel', () {
    test('memetakan semua field', () {
      final w = ProjectWorkerModel.fromJson(estProjectWorkerJson);
      expect(w.workerId, 11);
      expect(w.name, 'Andi Pratama');
      expect(w.nik, '3171000000000001');
      expect(w.photo, 'https://example.com/a.jpg');
      expect(w.clockIn, '07:05');
      expect(w.clockOut, '16:00');
      expect(w.isClockedIn, isTrue);
      expect(w.hoursToday, 8.5);
      expect(w.attendanceCondition, 2);
      expect(w.isSubstitute, isTrue);
      expect(w.substituteForName, 'Rudi');
      expect(w.assignmentId, 44);
      expect(w.initials, 'AP');
    });

    test('field opsional hilang memakai default DW', () {
      final w = ProjectWorkerModel.fromJson({'worker_id': 1});
      expect(w.name, '-');
      expect(w.nik, isNull);
      expect(w.photo, isNull);
      expect(w.clockIn, isNull);
      expect(w.clockOut, isNull);
      expect(w.isClockedIn, isFalse);
      expect(w.hoursToday, 0.0);
      expect(w.attendanceCondition, 1);
      expect(w.isSubstitute, isFalse);
      expect(w.substituteForName, isNull);
      expect(w.assignmentId, isNull);
    });
  });

  group('EstMandor', () {
    test('memetakan field', () {
      final m = EstMandor.fromJson(estEmployeeMandorJson);
      expect(m.id, 5);
      expect(m.name, 'Siti Aminah');
      expect(m.email, 'siti@example.com');
      expect(m.phone, '08123456789');
    });

    test('phone opsional', () {
      final m = EstMandor.fromJson({'id': 1, 'name': 'A', 'email': 'a@b.c'});
      expect(m.phone, isNull);
    });
  });

  group('EstAvailableWorker', () {
    test('memetakan field', () {
      final w = EstAvailableWorker.fromJson(estAvailableWorkerJson);
      expect(w.id, 21);
      expect(w.name, 'Dewi');
      expect(w.nik, '3171000000000002');
      expect(w.skills, 'Welder');
      expect(w.placement, 'Proyek Alpha');
    });

    test('default saat field hilang', () {
      final w = EstAvailableWorker.fromJson({'id': 1});
      expect(w.name, '-');
      expect(w.nik, '-');
      expect(w.skills, '-');
      expect(w.placement, isNull);
    });
  });

  group('ApiConfig EST', () {
    test('path endpoint', () {
      expect(ApiConfig.estExecutiveDashboard, '/api/est/dashboard/executive');
      expect(ApiConfig.estProjects, '/api/est/projects');
      expect(ApiConfig.estProject(3), '/api/est/projects/3');
      expect(ApiConfig.estProjectWorkers(3), '/api/est/projects/3/workers');
      expect(ApiConfig.estAssignTeam(3), '/api/est/projects/3/assign');
      expect(ApiConfig.estTransferWorkers(3),
          '/api/est/projects/3/workers/transfer');
      expect(ApiConfig.estCloseProject(3), '/api/est/projects/3/close');
      expect(ApiConfig.estSubstitute(3), '/api/est/projects/3/substitute');
      expect(
          ApiConfig.estEndSubstitute(3, 8), '/api/est/projects/3/substitute/8');
      expect(ApiConfig.estOpenSession(3), '/api/est/projects/3/sessions/open');
      expect(
          ApiConfig.estCloseSession(3), '/api/est/projects/3/sessions/close');
      expect(ApiConfig.estMandors, '/api/est/resources/mandors');
      expect(ApiConfig.estAvailableWorkers,
          '/api/est/resources/workers/available');
      expect(ApiConfig.estAllWorkers, '/api/est/resources/workers/all');
    });
  });
}
