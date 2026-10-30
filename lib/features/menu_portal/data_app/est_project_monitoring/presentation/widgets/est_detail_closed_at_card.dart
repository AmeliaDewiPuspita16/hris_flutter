import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../bloc/detail/exec_project_detail_bloc.dart';
import '../bloc/detail/exec_project_detail_state.dart';
import 'est_detail_format.dart';

/// Kartu "Proyek Selesai" dengan waktu penutupan; hanya muncul bila ada.
class EstDetailClosedAtCard extends StatelessWidget {
  const EstDetailClosedAtCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExecProjectDetailBloc, ExecProjectDetailState>(
      builder: (context, state) {
        if (state is! ExecProjectDetailLoaded) return const SizedBox.shrink();
        final closedAt = state.data.closedAt;
        if (closedAt == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.presentBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryText.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyek Selesai',
                      style: TextStyle(fontSize: 12, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estFmtDateTime(closedAt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
