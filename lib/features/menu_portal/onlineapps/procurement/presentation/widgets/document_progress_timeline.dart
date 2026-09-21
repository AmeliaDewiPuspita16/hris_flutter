import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/document_stage.dart';
import 'timeline_entry.dart';

/// Perjalanan dokumen PR: PR Approval -> Vendor Tally -> Purchase Order ->
/// Goods Receipt, beserta nomor dokumen yang sudah terbit di tiap tahap.
class DocumentProgressTimeline extends StatelessWidget {
  const DocumentProgressTimeline({super.key, required this.stages});

  final List<DocumentStage> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          TimelineEntry(
            color: stages[i].state.color,
            filled: stages[i].state.isFilled,
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
        // Judul dan keadaan sengaja dua Text bersebelahan tanpa pemisah "—"
        // seperti di web: di layar sempit keduanya boleh turun baris
        // sendiri-sendiri tanpa menyisakan tanda pisah menggantung.
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              stage.label,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    stage.state.isFilled ? AppColors.text : AppColors.textMid,
              ),
            ),
            Text(
              stage.stateLabel,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: stage.state.color,
              ),
            ),
          ],
        ),
        if (stage.numbers.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final number in stage.numbers) _DocumentNumber(number: number),
            ],
          ),
        ],
      ],
    );
  }
}

/// Nomor dokumen yang sudah terbit, mis. "BIIE/26-08-003".
class _DocumentNumber extends StatelessWidget {
  const _DocumentNumber({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMid,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
