import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Label kecil di atas kolom form.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }
}

/// Kolom teks berlabel dengan ikon awalan dan validator.
class EstFormTextField extends StatelessWidget {
  const EstFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color? color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: AppColors.textSub, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixText: suffix,
            suffixStyle: TextStyle(color: AppColors.textSub, fontSize: 13),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: border(null),
            focusedBorder: border(AppColors.primaryText, 1.5),
            errorBorder: border(AppColors.rejected),
            focusedErrorBorder: border(AppColors.rejected, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Kolom tanggal yang membuka date picker saat diketuk.
class EstFormDateField extends StatelessWidget {
  const EstFormDateField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSub,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          value != null ? AppColors.text : AppColors.textMuted,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol pembuka peta; menampilkan koordinat bila sudah dipilih.
class EstFormMapButton extends StatelessWidget {
  const EstFormMapButton({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasCoords ? AppColors.presentBg : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCoords
                ? AppColors.primaryText.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasCoords ? Icons.location_on : Icons.map_outlined,
              size: 18,
              color: hasCoords ? AppColors.primaryText : AppColors.textSub,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasCoords
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koordinat GPS dipilih',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${latitude!.toStringAsFixed(6)}, '
                          '${longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Pilih koordinat di peta (opsional)',
                      style: TextStyle(fontSize: 13, color: AppColors.textSub),
                    ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: hasCoords ? AppColors.primaryText : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
