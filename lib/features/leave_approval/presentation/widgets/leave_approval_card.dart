import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../pengajuan/domain/leave_type.dart';
import '../../domain/leave_approval_request.dart';
import '../../domain/leave_approval_status.dart';
import 'leave_approval_status_x.dart';

/// Kartu satu pengajuan di halaman Approvals.
///
/// Yang masih pending menampilkan tombol Reject/Approve langsung di kartu;
/// yang sudah diputuskan menampilkan badge status dan siapa yang memutuskan.
/// Tap kartu = buka detail lengkap.
///
/// Tampilannya sengaja polos: jenis pengajuan ditulis sebagai teks tebal,
/// lalu satu baris abu-abu untuk tanggal, jam, dan durasi. Tidak ada ikon
/// atau chip berwarna per jenis — kartu yang penuh warna-warni bersaing
/// dengan tombol Reject/Approve. Satu-satunya penanda warna adalah Overtime
/// (teks `violet`, sama dengan menu Overtime Request dan tombol filternya).
/// Detail lengkap tetap ada di [showLeaveApprovalDetailSheet].
class LeaveApprovalCard extends StatelessWidget {
  const LeaveApprovalCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onApprove,
    this.onReject,
    this.processing = false,
  });

  final LeaveApprovalRequest request;
  final VoidCallback onTap;

  /// Keduanya null pada tab History — tombol aksi tidak ditampilkan.
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// True selagi keputusan sedang dikirim: tombol diganti spinner.
  final bool processing;

  bool get _showActions =>
      request.isPending && onApprove != null && onReject != null;

  /// Tanggal · jam · durasi, tanpa nama jenis (sudah tampil di atasnya).
  String get _metaLine {
    final time = request.timeLabel == null ? '' : ' · ${request.timeLabel}';
    return '${request.dateLabel}$time · ${request.durationLabel}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(initials: request.initials),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${request.department} · ${request.position}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (request.isPending)
                Text(
                  DateFormatter.relative(request.submittedAt),
                  style: AppTextStyles.caption,
                )
              else
                StatusBadge(
                  status: request.status.appStatus,
                  label: request.status.label,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.type.label,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: request.isOvertime ? AppColors.violet : AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _metaLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
          if (request.reason != null) ...[
            const SizedBox(height: 8),
            Text(
              request.reason!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted.copyWith(height: 1.4),
            ),
          ],
          if (_showActions) ...[
            const SizedBox(height: 12),
            _buildActions(),
          ] else if (!request.isPending) ...[
            const SizedBox(height: 10),
            _buildDecisionFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (processing) {
      return const SizedBox(
        height: 38,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rejected,
                side: const BorderSide(color: AppColors.rejected, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
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
            height: 38,
            child: ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                'Approve',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionFooter() {
    final decidedAt = request.decidedAt;
    final by = request.decidedBy ?? 'Approver';
    final verb =
        request.status == LeaveApprovalStatus.approved ? 'Approved' : 'Rejected';
    final when =
        decidedAt == null ? '' : ' · ${DateFormatter.shortDateID(decidedAt)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        Text('$verb by $by$when', style: AppTextStyles.caption),
        if (request.decisionNote != null) ...[
          const SizedBox(height: 3),
          Text(
            request.decisionNote!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              height: 1.4,
              color: request.status == LeaveApprovalStatus.rejected
                  ? AppColors.rejected
                  : AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
