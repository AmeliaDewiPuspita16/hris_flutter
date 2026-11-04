import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_status.dart';

/// Pilihan penyaring daftar "Request Items".
class StationeryRequestFilter {
  const StationeryRequestFilter({this.status, this.onlyMine = false});

  /// Kode status yang dipilih ("pending" / "approved" / "rejected"), atau null
  /// untuk semua status.
  final String? status;

  /// True = hanya request milik sendiri.
  final bool onlyMine;

  bool get isActive => status != null || onlyMine;

  static const none = StationeryRequestFilter();
}

/// Bottom sheet "Filter", dibuka dari tombol di samping kolom search.
/// Mengembalikan [StationeryRequestFilter] saat "Apply" ditekan, atau null
/// bila ditutup tanpa menerapkan. "Reset" hanya mengosongkan pilihan di sheet;
/// baru berlaku setelah Apply.
class StationeryFilterSheet extends StatefulWidget {
  const StationeryFilterSheet({super.key, required this.initial});

  final StationeryRequestFilter initial;

  static Future<StationeryRequestFilter?> show(
    BuildContext context,
    StationeryRequestFilter initial,
  ) {
    return showModalBottomSheet<StationeryRequestFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationeryFilterSheet(initial: initial),
    );
  }

  @override
  State<StationeryFilterSheet> createState() => _StationeryFilterSheetState();
}

class _StationeryFilterSheetState extends State<StationeryFilterSheet> {
  late String? _status = widget.initial.status;
  late bool _onlyMine = widget.initial.onlyMine;

  static const _statuses = <(String?, String)>[
    (null, 'All status'),
    (StationeryRequestStatus.codePending, 'Pending'),
    (StationeryRequestStatus.codeApproved, 'Approved'),
    (StationeryRequestStatus.codeRejected, 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: Text('Filter', style: AppTextStyles.sectionTitle)),
                TextButton(
                  onPressed: () => setState(() {
                    _status = null;
                    _onlyMine = false;
                  }),
                  child: Text(
                    'Reset',
                    style: AppTextStyles.buttonText
                        .copyWith(color: AppColors.primaryText, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Status',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final (code, label) in _statuses)
              _ChoiceRow(
                label: label,
                dot: code == null
                    ? null
                    : StationeryRequestStatus(code: code, label: label).color,
                icon: _status == code
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                selected: _status == code,
                onTap: () => setState(() => _status = code),
              ),
            Divider(height: 20, color: AppColors.border),
            _ChoiceRow(
              label: 'Only my requests',
              icon: _onlyMine
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              selected: _onlyMine,
              onTap: () => setState(() => _onlyMine = !_onlyMine),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  StationeryRequestFilter(status: _status, onlyMine: _onlyMine),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris pilihan (radio untuk status, kotak centang untuk toggle).
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Titik warna status di depan label; null = tanpa titik.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
