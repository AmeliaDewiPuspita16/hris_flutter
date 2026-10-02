import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/department_attendance_status.dart';

/// Ringkasan status (Present, Late, No check-in, Leave) dalam satu kartu
/// empat kolom: angka di atas, label kecil di bawah.
///
/// Tiap kolom juga filter: ketuk untuk menyaring daftar, ketuk lagi untuk
/// membatalkan. Angka sengaja netral; satu-satunya warna adalah garis bawah
/// kolom yang aktif (warna status).
class AttendanceStatusChips extends StatelessWidget {
  const AttendanceStatusChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.isToday,
    required this.onSelected,
  });

  final Map<DepartmentAttendanceStatus, int> counts;

  /// Filter yang sedang aktif; null = semua.
  final DepartmentAttendanceStatus? selected;
  final bool isToday;

  /// Dipanggil dengan status yang diketuk, atau null kalau filter yang sama
  /// diketuk lagi (batal).
  final ValueChanged<DepartmentAttendanceStatus?> onSelected;

  static const _order = [
    DepartmentAttendanceStatus.hadir,
    DepartmentAttendanceStatus.terlambat,
    DepartmentAttendanceStatus.belumCheckIn,
    DepartmentAttendanceStatus.cuti,
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // Klip supaya riak InkWell kolom pertama/terakhir ikut sudut kartu.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              for (var i = 0; i < _order.length; i++)
                Expanded(
                  child: _Segment(
                    status: _order[i],
                    count: counts[_order[i]] ?? 0,
                    label: _order[i].label(isToday: isToday),
                    active: selected == _order[i],
                    showDivider: i > 0,
                    onTap: () => onSelected(
                      selected == _order[i] ? null : _order[i],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.status,
    required this.count,
    required this.label,
    required this.active,
    required this.showDivider,
    required this.onTap,
  });

  final DepartmentAttendanceStatus status;
  final int count;
  final String label;
  final bool active;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$count $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            border: Border(
              left: showDivider
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
              bottom: BorderSide(
                color: active ? status.color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTextStyles.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  fontSize: 11,
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
