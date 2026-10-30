import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_approval_item.dart';
import 'est_approve_hod_card.dart';

/// Dialog konfirmasi Approve di tab Approve HOD. Mengembalikan true bila
/// HOD menekan Approve, false bila dibatalkan.
Future<bool> showEstApproveDialog(
  BuildContext context,
  EstApprovalItem item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DecisionDialog(
      item: item,
      title: 'Approve request?',
      icon: Icons.check,
      color: AppColors.present,
      background: AppColors.presentBg,
      confirmLabel: 'Approve',
      confirmFilled: true,
      result: () => true,
    ),
  );
  return confirmed == true;
}

/// Dialog konfirmasi Reject di tab Approve HOD, dengan alasan opsional
/// (maks 1000 karakter — batas server untuk `reason`).
///
/// Mengembalikan alasan yang diketik (boleh string kosong) bila HOD
/// menekan Reject, atau null bila dibatalkan.
Future<String?> showEstRejectDialog(
  BuildContext context,
  EstApprovalItem item,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectDialog(item: item),
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.item});

  final EstApprovalItem item;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DecisionDialog(
      item: widget.item,
      title: 'Reject request?',
      icon: Icons.close,
      color: AppColors.rejected,
      background: AppColors.rejectedBg,
      confirmLabel: 'Reject',
      confirmFilled: false,
      result: () => _reasonController.text,
      extra: TextField(
        controller: _reasonController,
        maxLength: 1000,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Reason (optional)',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.card,
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primaryMid),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}

/// Kerangka dialog keputusan: ikon bulat + judul, ringkasan request, [extra]
/// opsional (kolom alasan), lalu tombol Cancel dan konfirmasi — bentuk
/// tombolnya sama dengan di kartu dan sheet detail.
///
/// [result] dipanggil saat tombol konfirmasi ditekan; nilainya jadi hasil
/// `showDialog`. Cancel / ketuk di luar dialog = pop tanpa nilai (null).
class _DecisionDialog extends StatelessWidget {
  const _DecisionDialog({
    required this.item,
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.confirmLabel,
    required this.confirmFilled,
    required this.result,
    this.extra,
  });

  final EstApprovalItem item;
  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final String confirmLabel;
  final bool confirmFilled;
  final Object? Function() result;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${item.requesterName} · ${item.department}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
            if (extra != null) ...[
              const SizedBox(height: 14),
              extra!,
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.border),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EstDecisionButton(
                    label: confirmLabel,
                    icon: icon,
                    filled: confirmFilled,
                    onPressed: () => Navigator.of(context).pop(result()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
