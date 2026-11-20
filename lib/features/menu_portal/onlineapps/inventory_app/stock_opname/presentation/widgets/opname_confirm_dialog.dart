import 'package:material_ui/material_ui.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Menampilkan [OpnameConfirmDialog] dan mengembalikan true bila tombol
/// konfirmasi ditekan; false bila dibatalkan atau ditutup.
Future<bool> showOpnameConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
  bool danger = false,
  String? subject,
  String? subjectNote,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => OpnameConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: icon,
      danger: danger,
      subject: subject,
      subjectNote: subjectNote,
    ),
  );
  return result == true;
}

/// Dialog konfirmasi: ikon bulat di atas, judul dan penjelasan di tengah,
/// kartu kecil yang menyebut apa yang terdampak ([subject], mis. kode
/// opname), lalu dua tombol berdampingan.
///
/// [danger] true untuk aksi yang merusak (hapus): ikon dan tombol berwarna
/// merah. Selain itu memakai warna utama aplikasi.
class OpnameConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;
  final bool danger;

  /// Hal yang terdampak, mis. "SOP00003". Null = kartu tidak ditampilkan.
  final String? subject;

  /// Keterangan kecil di sebelah kanan [subject], mis. "5 counted rows".
  final String? subjectNote;

  const OpnameConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.icon = Icons.help_outline_rounded,
    this.danger = false,
    this.subject,
    this.subjectNote,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.rejected : AppColors.primaryText;
    final accentBg = danger ? AppColors.rejectedBg : AppColors.primaryLight;
    final confirmColor =
        danger ? AppColors.solid(AppColors.rejected) : AppColors.primary;

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: accentBg, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(height: 1.45),
            ),
            if (subject != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (subjectNote != null) ...[
                      const SizedBox(width: 8),
                      Text(subjectNote!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.textSub,
                      side: BorderSide(color: AppColors.border),
                      shape: buttonShape,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: buttonShape,
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
