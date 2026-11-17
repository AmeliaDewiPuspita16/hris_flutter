import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/installed_meter.dart';
import '../../domain/meter_photo.dart';
import '../../domain/meter_value_format.dart';
import 'meter_type_avatar.dart';

/// Isian satu meter di form Record New Data: angka sebelumnya (terkunci),
/// angka sekarang (besar, fokus), pemakaian yang dihitung langsung, lalu
/// remark dan foto yang opsional.
///
/// Tidak menyimpan state apa pun — controller, foto, dan galatnya dimiliki
/// layar form, sama seperti `AddItRequestScreen`.
class MeterEntryCard extends StatelessWidget {
  const MeterEntryCard({
    super.key,
    required this.meter,
    required this.valueController,
    required this.remarkController,
    required this.photo,
    required this.errorText,
    required this.photoError,
    required this.usage,
    required this.enabled,
    required this.onChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final InstalledMeter meter;
  final TextEditingController valueController;
  final TextEditingController remarkController;
  final MeterPhoto? photo;

  /// Galat isian angka. Null bila belum ada yang perlu ditegur.
  final String? errorText;
  final String? photoError;

  /// Pemakaian bila isiannya sah dan angka sebelumnya diketahui.
  final num? usage;

  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final unit = meter.type.unit;
    final previous = meter.baselineForNextReading;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MeterTypeAvatar(type: meter.type, size: 36, soft: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'S/N ${meter.serialNumber}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      unit.isEmpty ? 'Meter' : unit,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _FillStatus(
                filled: valueController.text.trim().isNotEmpty && errorText == null,
                hasError: errorText != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LockedValue(
            label: 'PREVIOUS',
            value: previous == null
                ? '—'
                : '${formatMeterValue(previous)}${unit.isEmpty ? '' : ' $unit'}',
          ),
          const SizedBox(height: 14),
          _FieldLabel('CURRENT VALUE', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: valueController,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
            decoration: _decoration(
              hint: '0',
              suffix: unit,
              hasError: errorText != null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.topLeft,
            child: _Feedback(errorText: errorText, usage: usage, unit: unit),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _FieldLabel('REMARK'),
          const SizedBox(height: 6),
          TextField(
            controller: remarkController,
            enabled: enabled,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.done,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
            decoration: _decoration(
              hint: 'Optional, e.g. A, MSB-1',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          _PhotoRow(
            photo: photo,
            enabled: enabled,
            onPick: onPickPhoto,
            onRemove: onRemovePhoto,
          ),
          if (photoError != null) ...[
            const SizedBox(height: 8),
            Text(
              photoError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.rejected),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    String? suffix,
    bool hasError = false,
    required EdgeInsets contentPadding,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMuted,
      suffixText: (suffix == null || suffix.isEmpty) ? null : suffix,
      suffixStyle: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMid,
      ),
      isDense: true,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: contentPadding,
      enabledBorder: border(hasError ? AppColors.rejected : AppColors.border),
      disabledBorder: border(AppColors.border),
      focusedBorder: border(hasError ? AppColors.rejected : AppColors.primary, 1.5),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*', style: TextStyle(fontSize: 12, color: AppColors.accent)),
        ],
      ],
    );
  }
}

/// Angka sebelumnya: tampil, tidak bisa diubah (di web: "auto-filled").
class _LockedValue extends StatelessWidget {
  const _LockedValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _FieldLabel(label),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Satu baris di bawah kolom angka: galat bila isiannya salah, pemakaian
/// bila sah, atau kosong.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.errorText, required this.usage, required this.unit});

  final String? errorText;
  final num? usage;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.rejected.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: AppColors.rejected),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.rejected,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (usage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.presentBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: AppColors.present),
              const SizedBox(width: 8),
              Text(
                'Usage this period',
                style: AppTextStyles.caption.copyWith(color: AppColors.present),
              ),
              const Spacer(),
              Text(
                '${formatMeterValue(usage!)}${unit.isEmpty ? '' : ' $unit'}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.present,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photo,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final MeterPhoto? photo;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final current = photo;

    if (current == null) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: const Text('Add meter photo (optional)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryText,
            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
            textStyle: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Image.file(
              File(current.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.neutralBg,
                child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            current.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
          ),
        ),
        IconButton(
          onPressed: enabled ? onRemove : null,
          tooltip: 'Remove photo',
          icon: Icon(Icons.close_rounded, color: AppColors.textMid),
        ),
      ],
    );
  }
}

/// Penanda kecil di kepala kartu: sudah terisi / ada galat / belum diisi.
class _FillStatus extends StatelessWidget {
  const _FillStatus({required this.filled, required this.hasError});

  final bool filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String label;

    if (hasError) {
      icon = Icons.error_rounded;
      color = AppColors.rejected;
      label = 'Check value';
    } else if (filled) {
      icon = Icons.check_circle_rounded;
      color = AppColors.present;
      label = 'Ready';
    } else {
      icon = Icons.radio_button_unchecked_rounded;
      color = AppColors.textMuted;
      label = 'To fill';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
