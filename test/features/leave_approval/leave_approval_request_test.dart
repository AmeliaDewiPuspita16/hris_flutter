import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/leave_approval/domain/leave_approval_request.dart';
import 'package:hris_mobile/features/leave_approval/domain/leave_approval_status.dart';
import 'package:hris_mobile/features/pengajuan/domain/leave_type.dart';

/// Shape of `GET /api/portal/apps/hris/leave/approvals` rows.
Map<String, dynamic> row(Map<String, dynamic> overrides) => {
      'id': 'CA6769393BCB428F8D9783CC8BAF7AE8',
      'nik': '0788',
      'requester_name': 'Noval Sandy Hidayat',
      'department': 'IT & MEDIA',
      'type': 'Cuti Tahunan',
      'start_date': '2026-11-10',
      'end_date': '2026-11-11',
      'is_hourly': false,
      'days': 2,
      'description': 'Family event',
      'is_urgent': false,
      'submitted_at': '2026-11-06T17:06:20+07:00',
      'status': 'pending',
      'status_code': 'OEZ_RELEASE',
      'updated_by': 'Sulastri',
      'updated_at': '2026-11-07T09:00:00+07:00',
      ...overrides,
    };

void main() {
  test('pending row', () {
    final r = LeaveApprovalRequest.fromJson(row({}));

    expect(r.status, LeaveApprovalStatus.pending);
    expect(r.type, LeaveType.cutiTahunan);
    expect(r.requesterName, 'Noval Sandy Hidayat');
    expect(r.position, 'NIK 0788');
    expect(r.durationLabel, '2 days');
    expect(r.endDate, DateTime(2026, 11, 11));
    expect(r.decidedBy, isNull);
    expect(r.decidedAt, isNull);
  });

  test('decided rows carry who changed them last', () {
    final approved = LeaveApprovalRequest.fromJson(row({'status': 'approved', 'days': 1}));
    expect(approved.status, LeaveApprovalStatus.approved);
    expect(approved.decidedBy, 'Sulastri');
    expect(approved.decidedAt, isNotNull);
    expect(approved.durationLabel, '1 day');

    final voided = LeaveApprovalRequest.fromJson(row({'status': 'voided', 'days': 0.5}));
    expect(voided.status, LeaveApprovalStatus.voided);
    expect(voided.durationLabel, 'Half day');
  });

  test('overtime row', () {
    final r = LeaveApprovalRequest.fromJson(row({
      'category': 'overtime',
      'type': 'Overtime',
      'end_date': null,
      'start_time': '17:00',
      'end_time': '20:30',
      'days': null,
      'hours': 3.5,
    }));

    expect(r.type, LeaveType.lembur);
    expect(r.isOvertime, isTrue);
    expect(r.endDate, isNull);
    expect(r.timeLabel, '17:00–20:30');
    expect(r.durationLabel, '3h 30m');
    expect(LeaveApprovalRequest.fromJson(row({'type': 'Overtime', 'hours': 4})).durationLabel, '4h');
  });

  test('OIL maps to Off in Lieu, unknown names do not throw', () {
    expect(LeaveApprovalRequest.fromJson(row({'type': 'OIL'})).type, LeaveType.cutiPengganti);
    expect(LeaveApprovalRequest.fromJson(row({'type': 'Something New'})).type, LeaveType.izin);
    expect(LeaveApprovalRequest.fromJson(row({'description': '  ', 'nik': null})).reason, isNull);
  });
}
