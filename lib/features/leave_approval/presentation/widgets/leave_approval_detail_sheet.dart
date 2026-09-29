import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../pengajuan/domain/leave_type.dart';
import '../../domain/leave_approval_request.dart';
import '../../domain/leave_approval_status.dart';
import 'leave_approval_status_x.dart';

/// Detail lengkap satu pengajuan dalam bottom sheet.
///
/// Mengembalikan keputusan yang dipilih approver lewat tombol di bawah
/// (hanya untuk yang masih pending), atau null kalau sheet ditutup begitu
/// saja. Sheet ini TIDAK mengirim keputusan sendiri — pemanggil yang
/// melanjutkan ke sheet konfirmasi, supaya alurnya sama persis dengan tombol
/// di kartu.
Future<LeaveApprovalDecision?> showLeaveApprovalDetailSheet(
  BuildContext context,
  LeaveApprovalRequest request, {
  bool canDecide = true,
}) {
  return showModalBottomSheet<LeaveApprovalDecision>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LeaveApprovalDetailSheet(
      request: request,
      canDecide: canDecide && request.isPending,
    ),
  );
}

class _LeaveApprovalDetailSheet extends StatelessWidget {
  const _LeaveApprovalDetailSheet({
    required this.request,
    required this.canDecide,
  });

  final LeaveApprovalRequest request;
  final bool canDecide;

  @override
  Widget build(BuildContext context) {
    final type = request.type;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: type.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: type.color,
                    ),
                  ),
                ),
                StatusBadge(
                  status: request.status.appStatus,
                  label: request.status.label,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    request.initials,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.department} · ${request.position}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _Field(label: 'Date', value: request.dateLabel),
            if (request.timeLabel != null)
              _Field(label: 'Time', value: request.timeLabel!),
            _Field(label: 'Duration', value: request.durationLabel),
            _Field(label: 'Reason', value: request.reason ?? '-'),
            if (request.balanceInfo != null)
              _Field(
                label: '${type.label} balance (before this request)',
                value: request.balanceInfo!,
              ),
            if (request.attachmentName != null) ...[
              const _FieldLabel('Attachment'),
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
                    const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.attachmentName!,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _Field(
              label: 'Submitted',
              value: '${DateFormatter.shortDateID(request.submittedAt)}'
                  ' · ${DateFormatter.relative(request.submittedAt)}',
            ),
            if (!request.isPending) ..._buildDecision(),
            if (canDecide) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(LeaveApprovalDecision.reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.rejected,
                          side: const BorderSide(
                            color: AppColors.rejected,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.rejected,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(LeaveApprovalDecision.approve),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Approve',
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecision() {
    final decidedAt = request.decidedAt;
    final verb =
        request.status == LeaveApprovalStatus.approved ? 'Approved' : 'Rejected';
    final when =
        decidedAt == null ? '' : ' · ${DateFormatter.shortDateID(decidedAt)}';

    return [
      _Field(
        label: 'Decision',
        value: '$verb by ${request.decidedBy ?? 'Approver'}$when',
      ),
      if (request.decisionNote != null)
        _Field(label: 'Approver note', value: request.decisionNote!),
    ];
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}
