import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/request_category.dart';

/// Dropdown pilihan "Request type" (IT / Media).
///
/// Sebelumnya dua kartu berikon — diganti jadi dropdown polos tanpa ikon,
/// konsisten dengan dropdown lain di form ini (mis. Department, Executive
/// type pada [NewEmployeeSubform]). Label + tanda "REQUIRED" tetap datang
/// dari [FieldLabelRow] di [AddItRequestScreen], jadi widget ini sengaja
/// tidak merender label sendiri supaya tidak dobel.
class RequestCategorySelector extends StatelessWidget {
  const RequestCategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RequestCategory? value;
  final ValueChanged<RequestCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<RequestCategory>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textMuted,
          size: 18,
        ),
        style: AppTextStyles.body.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(10),
        hint: Text(
          '-- Select --',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        items: [
          for (final category in RequestCategory.values)
            DropdownMenuItem(
              value: category,
              child: Text(
                category.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
