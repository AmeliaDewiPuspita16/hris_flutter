import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/document_stage.dart';
import 'timeline_entry.dart';

/// Perjalanan dokumen PR: PR Approval -> Vendor Tally -> Purchase Order ->
/// Goods Receipt, dengan rincian tahap di dalam "PR Approval".
class DocumentProgressTimeline extends StatelessWidget {
  const DocumentProgressTimeline({super.key, required this.stages});

  final List<DocumentStage> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          TimelineEntry(
            state: stages[i].state,
            isLast: i == stages.length - 1,
            child: _StageContent(stage: stages[i]),
          ),
      ],
    );
  }
}

class _StageContent extends StatelessWidget {
  const _StageContent({required this.stage});

  final DocumentStage stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul dan status sengaja jadi dua Text bersebelahan tanpa pemisah
        // "—" seperti di web: di layar sempit keduanya boleh turun baris
        // sendiri-sendiri tanpa menyisakan tanda pisah menggantung.
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              stage.title,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: stage.state.isFilled ? AppColors.text : AppColors.textMid,
              ),
            ),
            Text(
              stage.statusLabel,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: stage.state.color,
              ),
            ),
          ],
        ),
        for (final sub in stage.subSteps)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: sub.state.isFilled
                        ? sub.state.color
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  sub.label,
                  style: AppTextStyles.caption.copyWith(
                    color: sub.state.isFilled
                        ? AppColors.textMid
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.note != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sub.note!,
                      style: AppTextStyles.caption.copyWith(color: sub.state.color),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
