import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/leave_approval_request.dart';
import '../../domain/leave_approval_status.dart';

/// Sheet konfirmasi sebelum keputusan dikirim, dengan kolom catatan.
///
/// - Approve: catatan opsional.
/// - Reject: catatan WAJIB (tombol konfirmasi mati selama kosong), supaya
///   pemohon selalu tahu alasan penolakannya.
///
/// Mengembalikan catatan yang sudah di-trim (bisa string kosong untuk
/// approve tanpa catatan), atau `null` kalau approver membatalkan.
Future<String?> showLeaveDecisionSheet(
  BuildContext context, {
  required LeaveApprovalRequest request,
  required LeaveApprovalDecision decision,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LeaveDecisionSheet(request: request, decision: decision),
  );
}

class _LeaveDecisionSheet extends StatefulWidget {
  const _LeaveDecisionSheet({required this.request, required this.decision});

  final LeaveApprovalRequest request;
  final LeaveApprovalDecision decision;

  @override
  State<_LeaveDecisionSheet> createState() => _LeaveDecisionSheetState();
}

class _LeaveDecisionSheetState extends State<_LeaveDecisionSheet> {
  final _noteController = TextEditingController();

  bool get _isApprove => widget.decision == LeaveApprovalDecision.approve;

  bool get _canConfirm => _isApprove || _noteController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Supaya tombol konfirmasi ikut hidup/mati mengikuti isi catatan.
    _noteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final accent = _isApprove ? AppColors.primary : AppColors.rejected;

    return Padding(
      // Naik mengikuti keyboard supaya kolom catatan tidak ketutupan.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
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
                Text(
                  _isApprove ? 'Approve this request?' : 'Reject this request?',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  request.requesterName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(request.summaryLine, style: AppTextStyles.caption),
                const SizedBox(height: 16),
                AppTextField(
                  label: _isApprove ? 'Note (optional)' : 'Reason for rejection',
                  controller: _noteController,
                  hint: _isApprove
                      ? 'Add a note for the requester...'
                      : 'Tell the requester why this is rejected...',
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.textMid,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _canConfirm
                              ? () => Navigator.of(context)
                                  .pop(_noteController.text.trim())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            disabledBackgroundColor: AppColors.border,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isApprove ? 'Approve' : 'Reject',
                            style: AppTextStyles.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
