import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/domain/role.dart';
import 'hris_menu_item.dart';

/// Daftar item menu HRIS.
///
/// Semua yang berhubungan dengan "item apa ada di menu, untuk siapa, dan
/// sudah siap atau belum" ada di sini. Menambah fitur baru = menambah satu
/// entri di [items]. Disusun sebagai function (bukan konstanta) karena tiap
/// item butuh callback navigasi dari `BerandaScreen`, pola yang sama dengan
/// `OnlineAppsDemoData`.
///
/// Peta baris requirement (LIST_VIEW_HRIS_DI_HP.xlsx) → item di sini:
///  1. Employee information (view & data change request) → employee_info
///  2. Company Announcement → BUKAN item menu ini — sudah tampil sebagai
///     feed di Beranda (lihat `AnnouncementSection`); ditinggalkan di sana
///     supaya tidak ada dua tempat untuk hal yang sama.
///  3. Pay Slip → payslip (belum siap, data payroll dari vendor belum ada)
///  4. Leave balance (view semua; edit oleh HOD & Admin Dep) → saldo di
///     leave_request (view); edit oleh HOD/Admin → leave_balance_edit
///     (belum siap, belum ada layarnya)
///  5. Annual Leave request → leave_request
///  6. Leave approval (HOD) → approvals
///  7. Leave permission (edit & view) → leave_request
///  8. Medical check balance (edit oleh HOD & Admin Dep) → leave_balance_edit
///  9. Medical check request → leave_request
/// 10. Off in lieu balance (edit oleh HOD & Admin Dep, Executive ke atas)
///     → leave_balance_edit
/// 11. Off in lieu request (Executive ke atas) → leave_request
/// 12. Off in lieu approval (HOD) → approvals
/// 13. Overtime balance (edit oleh HOD & Admin Dep, Non-Executive) → leave_balance_edit
/// 14. Overtime request (edit & view, Non-Executive) → leave_request
/// 15. Overtime approval (HOD) → approvals
/// 16. Personal Attendance Log (All + HOD) → attendance_log
/// 17. Department Attendance Log (Admin Dep, superior, HOD) → dept_attendance
/// 18. Personal work schedule/shift → work_schedule (belum siap)
/// 19. Department work schedule/shift (Admin Dep, superior, HOD)
///     → dept_schedule (belum siap)
///
/// Item nomor 4–15 sengaja digabung jadi satu layar [leave_request]
/// (Summary/Submit/Status) karena semuanya satu alur yang sama; jenisnya
/// (Annual Leave, Permission, Medical Check, Off in Lieu, Overtime)
/// dibedakan di dalam layar itu sendiri lewat `LeaveType`, bukan di menu.
class HrisMenuConfig {
  HrisMenuConfig._();

  // SEMENTARA: aturan visibilitas masih berbasis enum Role yang dipatok di
  // AuthGate. Ganti ke kemampuan dari AuthUser.roles setelah pemetaan role
  // dari backend diputuskan (siapa "superior", "Admin Dep", "Executive").
  static bool _isHod(HrisMenuContext c) => c.role == Role.hod;

  static bool _isHodOrAdmin(HrisMenuContext c) =>
      c.role == Role.hod || c.role == Role.admin;

  /// Menyembunyikan item sepenuhnya (beda dari `isReady: false` yang tetap
  /// tampil redup berlabel "Soon"). Dipakai untuk fitur yang belum akan
  /// dibuat di mobile.
  static bool _hidden(HrisMenuContext c) => false;

  static void _noop() {}

  static List<HrisMenuItem> items({
    required VoidCallback onAttendance,
    required VoidCallback onLeaveRequest,
    required VoidCallback onEmployeeInfo,
    required VoidCallback onPayslip,
    required VoidCallback onManageTeam,
    required VoidCallback onDepartmentAttendance,
    required VoidCallback onApprovals,
    int approvalCount = 0,
  }) =>
      [
        // ── Attendance ─────────────────────────────────────────────────
        HrisMenuItem(
          id: 'attendance_log',
          label: 'Attendance Log',
          icon: Icons.fingerprint,
          group: HrisMenuGroup.attendance,
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onAttendance,
        ),
        const HrisMenuItem(
          id: 'work_schedule',
          label: 'Work Schedule',
          icon: Icons.calendar_month_outlined,
          group: HrisMenuGroup.attendance,
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: _noop,
          isReady: false,
          // Disembunyikan: jadwal shift pribadi sudah tampil per tanggal di
          // kalender Attendance Log.
          isVisible: _hidden,
        ),
        HrisMenuItem(
          id: 'dept_attendance',
          label: 'Department\nAttendance Log',
          icon: Icons.fact_check_outlined,
          group: HrisMenuGroup.attendance,
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onDepartmentAttendance,
          isVisible: _isHodOrAdmin,
        ),
        const HrisMenuItem(
          id: 'dept_schedule',
          label: 'Department\nWork Schedule',
          icon: Icons.calendar_view_week_outlined,
          group: HrisMenuGroup.attendance,
          color: AppColors.orange,
          background: AppColors.orangeBg,
          onTap: _noop,
          isReady: false,
          // Disembunyikan dulu: penyusunan jadwal shift tetap di web.
          // Ganti ke `_isHodOrAdmin` kalau nanti dibuat versi lihat-saja.
          isVisible: _hidden,
        ),

        // ── Leave & Time Off ───────────────────────────────────────────
        // Satu pintu untuk Annual Leave, Permission, Medical Check,
        // Off in Lieu, dan Overtime — jenisnya dibedakan di dalam layar,
        // bukan di menu. Lihat catatan di komentar kelas.
        HrisMenuItem(
          id: 'leave_request',
          label: 'Leave & Time Off',
          icon: Icons.event_available_outlined,
          group: HrisMenuGroup.leave,
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onLeaveRequest,
        ),
        HrisMenuItem(
          id: 'approvals',
          label: 'Leave Approvals',
          icon: Icons.task_alt,
          group: HrisMenuGroup.leave,
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onApprovals,
          isVisible: _isHod,
          badgeCount: approvalCount,
        ),
        const HrisMenuItem(
          id: 'leave_balance_edit',
          label: 'Leave Balance\n(Edit)',
          icon: Icons.edit_calendar_outlined,
          group: HrisMenuGroup.leave,
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: _noop,
          isReady: false,
          isVisible: _isHodOrAdmin,
        ),

        // ── Employee ───────────────────────────────────────────────────
        HrisMenuItem(
          id: 'employee_info',
          label: 'Employee\nInformation',
          icon: Icons.badge_outlined,
          group: HrisMenuGroup.employee,
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onEmployeeInfo,
          isReady: false,
        ),
        HrisMenuItem(
          id: 'payslip',
          label: 'Pay Slip',
          icon: Icons.receipt_long_outlined,
          group: HrisMenuGroup.employee,
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onPayslip,
          // Ubah ke true saat data payroll dari vendor sudah tersambung.
          isReady: false,
        ),

        // ── Team ───────────────────────────────────────────────────────
        HrisMenuItem(
          id: 'manage_team',
          label: 'Manage Team',
          icon: Icons.groups_outlined,
          group: HrisMenuGroup.team,
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onManageTeam,
          // SEMENTARA: tanpa gerbang role dulu, karena role di AuthGate masih
          // dipatok (Role.hrPublisher) sehingga item ini selalu tersembunyi.
          // Kembalikan ke `isVisible: _isHodOrAdmin` setelah pemetaan role
          // dari API diputuskan.
        ),
      ];
}
