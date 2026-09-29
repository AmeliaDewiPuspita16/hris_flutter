import '../../pengajuan/domain/leave_type.dart';
import 'leave_approval_request.dart';
import 'leave_approval_status.dart';

/// Data contoh untuk halaman Leave Approvals, sampai endpoint approval HRIS
/// tersedia.
///
/// Dibuat sebagai fungsi (bukan konstanta) karena tanggalnya dihitung
/// relatif terhadap sekarang, supaya label "25m ago" dan tanggal cuti yang
/// akan datang selalu masuk akal kapan pun aplikasi dibuka.
///
/// Dipakai dua tempat: `LeaveApprovalRepository` (isi halaman) dan
/// `NotificationDemoData` (notifikasi yang menunggu keputusan) — jadi
/// keduanya selalu membahas pengajuan yang sama.
class LeaveApprovalDemoData {
  LeaveApprovalDemoData._();

  static List<LeaveApprovalRequest> requests({DateTime? now}) {
    final reference = now ?? DateTime.now();

    DateTime day(int offset) =>
        DateTime(reference.year, reference.month, reference.day + offset);

    return [
      // ── Menunggu keputusan ───────────────────────────────────────
      LeaveApprovalRequest(
        id: 'LA-1041',
        requesterName: 'Budi Santoso',
        department: 'Production',
        position: 'Operator',
        type: LeaveType.cutiTahunan,
        startDate: day(7),
        endDate: day(9),
        durationLabel: '3 days',
        reason: 'Family event in Yogyakarta. Work handover to Andi has '
            'already been arranged.',
        balanceInfo: '8 of 12 days left',
        submittedAt: reference.subtract(const Duration(minutes: 25)),
      ),
      LeaveApprovalRequest(
        id: 'LA-1042',
        requesterName: 'Rina Wijaya',
        department: 'Logistics',
        position: 'Admin Logistics',
        type: LeaveType.lembur,
        startDate: day(-1),
        timeLabel: '18:30–21:00',
        durationLabel: '2h 30m',
        reason: 'Container loading for an urgent shipment.',
        balanceInfo: '14.5 hours accumulated',
        submittedAt: reference.subtract(const Duration(hours: 2)),
      ),
      LeaveApprovalRequest(
        id: 'LA-1043',
        requesterName: 'Agus Prasetyo',
        department: 'Maintenance',
        position: 'Technician',
        type: LeaveType.izin,
        startDate: day(2),
        timeLabel: 'Morning',
        durationLabel: 'Half day',
        reason: 'Renewing driving license at Samsat.',
        balanceInfo: '4 of 6 days left',
        submittedAt: reference.subtract(const Duration(hours: 5)),
      ),
      LeaveApprovalRequest(
        id: 'LA-1044',
        requesterName: 'Sari Utami',
        department: 'Quality Control',
        position: 'QC Inspector',
        type: LeaveType.cekKesehatan,
        startDate: day(10),
        durationLabel: '1 day',
        reason: 'Annual company medical check-up.',
        attachmentName: 'mcu_invitation.pdf',
        balanceInfo: '1 of 1 left',
        submittedAt: reference.subtract(const Duration(days: 1, hours: 2)),
      ),
      LeaveApprovalRequest(
        id: 'LA-1045',
        requesterName: 'Dimas Anggara',
        department: 'Finance',
        position: 'Finance Executive',
        type: LeaveType.cutiPengganti,
        startDate: day(14),
        durationLabel: '1 day',
        reason: 'Off in lieu for the weekend month-end closing work.',
        balanceInfo: '3 of 5 days left',
        submittedAt: reference.subtract(const Duration(days: 1, hours: 6)),
      ),

      // ── Sudah diputuskan (untuk tab History) ─────────────────────
      LeaveApprovalRequest(
        id: 'LA-1038',
        requesterName: 'Maya Lestari',
        department: 'Production',
        position: 'Operator',
        type: LeaveType.cutiTahunan,
        startDate: day(-12),
        endDate: day(-10),
        durationLabel: '3 days',
        reason: 'Family trip to Bandung.',
        submittedAt: reference.subtract(const Duration(days: 16)),
        status: LeaveApprovalStatus.approved,
        decidedBy: 'You',
        decidedAt: reference.subtract(const Duration(days: 15)),
      ),
      LeaveApprovalRequest(
        id: 'LA-1037',
        requesterName: 'Eko Nugroho',
        department: 'Warehouse',
        position: 'Warehouse Staff',
        type: LeaveType.izin,
        startDate: day(-20),
        durationLabel: 'Full day',
        reason: 'Personal errand.',
        submittedAt: reference.subtract(const Duration(days: 22)),
        status: LeaveApprovalStatus.rejected,
        decidedBy: 'You',
        decidedAt: reference.subtract(const Duration(days: 21)),
        decisionNote: 'Stock opname is scheduled that day. '
            'Please resubmit for the following week.',
      ),
      LeaveApprovalRequest(
        id: 'LA-1036',
        requesterName: 'Rina Wijaya',
        department: 'Logistics',
        position: 'Admin Logistics',
        type: LeaveType.lembur,
        startDate: day(-25),
        timeLabel: '18:30–21:30',
        durationLabel: '3h 00m',
        reason: 'Inventory reconciliation before audit.',
        submittedAt: reference.subtract(const Duration(days: 26)),
        status: LeaveApprovalStatus.approved,
        decidedBy: 'You',
        decidedAt: reference.subtract(const Duration(days: 25)),
      ),
    ];
  }
}
