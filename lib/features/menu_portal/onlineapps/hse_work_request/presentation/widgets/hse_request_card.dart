import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../domain/hse_request_category.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_work_request.dart';
import 'hse_page_chrome.dart';

/// Kartu satu permit di daftar: ikon dokumen di kiri, nomor register +
/// nama PIC + departemen + kategori di tengah, status dan chevron di kanan,
/// lalu lokasi dan rentang tanggal di bawah.
///
/// [footer] opsional di bawah kartu, mis. tombol Approve/Reject di tab
/// approval.
class HseRequestCard extends StatelessWidget {
  const HseRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.footer,
  });

  final HseWorkRequest request;
  final VoidCallback onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final department = hseDepartmentLine(request.department, request.section);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      elevation: AppColors.isDark ? 0 : 1.5,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PermitIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.idRegister ?? '#${request.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.pic,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        if (department.isNotEmpty)
                          Text(department, style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        StatusBadge.custom(
                          label: request.category.shortLabel,
                          color: AppColors.textMid,
                          background: AppColors.neutralBg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge status di atas chevron, supaya nomor register
                  // mendapat lebar penuh kolom tengah.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        status: request.status.appStatus,
                        label: request.displayStatus,
                      ),
                      const SizedBox(height: 14),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 68, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (request.location.isNotEmpty)
                      _IconText(
                        icon: Icons.place_outlined,
                        text: request.location,
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _IconText(
                        icon: Icons.calendar_today_outlined,
                        text: hseDateRange(request.dateStart, request.dateEnd),
                        expand: false,
                      ),
                    ),
                  ],
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: footer!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak ikon dokumen bercentang di kiri kartu.
class _PermitIcon extends StatelessWidget {
  const _PermitIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.presentBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.assignment_turned_in_outlined,
        size: 28,
        color: AppColors.primaryText,
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
    this.expand = true,
  });

  final IconData icon;
  final String text;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption.copyWith(fontSize: 11),
    );
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        expand ? Expanded(child: label) : label,
      ],
    );
  }
}
