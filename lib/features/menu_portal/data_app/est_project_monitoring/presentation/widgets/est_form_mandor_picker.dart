import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/est_mandor.dart';

/// Pilihan supervisor (mandor) di form proyek: loading, error + coba lagi,
/// atau dropdown, plus banner konfirmasi setelah dipilih.
class EstFormMandorPicker extends StatelessWidget {
  const EstFormMandorPicker({
    super.key,
    required this.mandors,
    required this.loading,
    required this.error,
    required this.selected,
    required this.onRetry,
    required this.onChanged,
  });

  final List<EstMandor> mandors;
  final bool loading;
  final String? error;
  final EstMandor? selected;
  final VoidCallback onRetry;
  final ValueChanged<EstMandor?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Supervisor',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        if (loading)
          _loading()
        else if (error != null)
          _error()
        else
          _dropdown(),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryText,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selected!.name} akan menjadi Supervisor proyek ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _loading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat daftar supervisor...',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rejected, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(fontSize: 12, color: AppColors.rejected),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Coba lagi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.rejected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null ? AppColors.primaryText : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstMandor>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Pilih supervisor...',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSub),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          items: mandors
              .map(
                (m) => DropdownMenuItem<EstMandor>(
                  value: m,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.presentBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            m.name[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              m.phone ?? m.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
