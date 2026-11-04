import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/exec_project_full.dart';
import '../bloc/detail/exec_project_detail_bloc.dart';
import '../bloc/detail/exec_project_detail_state.dart';
import 'est_detail_format.dart';

/// Kartu "Supervisor / PIC". [onSubstitute] dan [onEndSubstitute] null = aksi
/// pengganti belum tersambung (tombolnya tetap tampil tanpa efek).
class EstDetailMandorSection extends StatelessWidget {
  const EstDetailMandorSection({
    super.key,
    this.onSubstitute,
    this.onEndSubstitute,
  });

  final void Function(MandorModel mandor)? onSubstitute;
  final void Function(MandorModel mandor)? onEndSubstitute;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExecProjectDetailBloc, ExecProjectDetailState>(
      builder: (context, state) {
        if (state is ExecProjectDetailLoading ||
            state is ExecProjectDetailInitial) {
          return const AppShimmer(
            child: ShimmerBox(height: 80, borderRadius: 16),
          );
        }
        if (state is ExecProjectDetailLoaded) {
          final mandors = state.data.mandors;
          if (mandors.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: estCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.orangeBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.manage_accounts_outlined,
                        size: 15,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      mandors.length == 1
                          ? 'Supervisor / PIC'
                          : 'Supervisor / PIC (${mandors.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...mandors.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return Column(
                    children: [
                      if (i > 0) Divider(height: 1, color: AppColors.border),
                      if (i > 0) const SizedBox(height: 8),
                      _MandorRow(
                        mandor: m,
                        onSubstitute: onSubstitute == null
                            ? null
                            : () => onSubstitute!(m),
                        onEndSubstitute: onEndSubstitute == null
                            ? null
                            : () => onEndSubstitute!(m),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _MandorRow extends StatelessWidget {
  const _MandorRow({
    required this.mandor,
    this.onSubstitute,
    this.onEndSubstitute,
  });

  final MandorModel mandor;
  final VoidCallback? onSubstitute;
  final VoidCallback? onEndSubstitute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: mandor.isSubstitute
                ? AppColors.solid(AppColors.orange)
                : AppColors.orangeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              mandor.initials,
              style: TextStyle(
                color: mandor.isSubstitute ? Colors.white : AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mandor.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              if (mandor.isSubstitute && mandor.substituteFor != null)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pengganti ${mandor.substituteFor!.name}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (mandor.isSubstitute && mandor.assignmentId != null)
          GestureDetector(
            onTap: onEndSubstitute,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.rejectedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Akhiri',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rejected,
                ),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: onSubstitute,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.presentBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_add_alt_1_outlined,
                size: 16,
                color: AppColors.primaryText,
              ),
            ),
          ),
      ],
    );
  }
}
