import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/department_attendance_entry.dart';
import '../../domain/department_attendance_recap.dart';

/// Tabel rekap bulanan: nama + jabatan di kiri, lalu kolom Late, Absent, dan
/// Leave. Angka netral; angka 0 diredupkan supaya yang bermasalah menonjol
/// tanpa perlu warna. Baris bisa diketuk untuk membuka detail bulan karyawan.
class DepartmentAttendanceRecapTable extends StatelessWidget {
  const DepartmentAttendanceRecapTable({
    super.key,
    required this.rows,
    required this.onTapRow,
  });

  final List<DepartmentAttendanceRecapRow> rows;
  final ValueChanged<DepartmentAttendanceEntry> onTapRow;

  static const _lateWidth = 44.0;
  static const _absentWidth = 54.0;
  static const _leaveWidth = 46.0;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // Klip supaya riak InkWell baris pertama/terakhir ikut sudut kartu.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              const _HeaderRow(),
              for (final row in rows) ...[
                const Divider(height: 1, color: AppColors.border),
                _DataRow(row: row, onTap: () => onTapRow(row.entry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  static const _style = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  Widget _cell(String text, double width) => SizedBox(
        width: width,
        child: Text(text, textAlign: TextAlign.center, style: _style),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Text('Employee', style: _style)),
          _cell('Late', DepartmentAttendanceRecapTable._lateWidth),
          _cell('Absent', DepartmentAttendanceRecapTable._absentWidth),
          _cell('Leave', DepartmentAttendanceRecapTable._leaveWidth),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.row, required this.onTap});

  final DepartmentAttendanceRecapRow row;
  final VoidCallback onTap;

  Widget _count(int value, double width) => SizedBox(
        width: width,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: value == 0 ? FontWeight.w400 : FontWeight.w700,
            color: value == 0 ? AppColors.textMuted : AppColors.text,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    row.entry.position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            _count(row.lateCount, DepartmentAttendanceRecapTable._lateWidth),
            _count(
              row.absentCount,
              DepartmentAttendanceRecapTable._absentWidth,
            ),
            _count(row.leaveCount, DepartmentAttendanceRecapTable._leaveWidth),
          ],
        ),
      ),
    );
  }
}
