import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/leave_history_entry.dart';

/// Detail satu pengajuan (alasan, lampiran, catatan approval) dalam bottom
/// sheet. Sengaja dipisah jadi fungsi + widget sendiri supaya tab Ringkasan
/// dan tab Status bisa sama-sama panggil ini saat barisnya ditap, tanpa
/// perlu dua versi tampilan detail yang beda.
Future<void> showLeaveDetailSheet(BuildContext context, LeaveHistoryEntry entry) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _LeaveDetailSheet(entry: entry),
  );
}

class _LeaveDetailSheet extends StatelessWidget {
  const _LeaveDetailSheet({required this.entry});

  final LeaveHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: entry.typeBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.type,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: entry.typeColor),
                ),
              ),
              StatusBadge(status: entry.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 18),
          _DetailField(label: 'Reason', value: entry.reason ?? '-'),
          if (entry.photoUrl != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Attachment',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.photoUrl!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DetailField(label: 'Notes', value: entry.note, valueColor: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value, this.valueColor = AppColors.text});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor, height: 1.4)),
      ],
    );
  }
}
