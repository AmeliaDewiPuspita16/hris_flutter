import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/need_option.dart';

/// Satu baris radio pada daftar "What do you need?".
///
/// Kalau [selected] true dan [option] punya field tambahan, [expandedChild]
/// dirender langsung di bawah label — dibangun oleh pemanggil lewat
/// switch atas [NeedOption.fieldKind] (lihat `add_it_request_screen.dart`).
class NeedOptionTile extends StatelessWidget {
  const NeedOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelect,
    this.expandedChild,
  });

  final NeedOption option;
  final bool selected;
  final VoidCallback onSelect;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryMid : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(option.label, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          if (selected && expandedChild != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 0, 12, 14),
              child: expandedChild,
            ),
        ],
      ),
    );
  }
}