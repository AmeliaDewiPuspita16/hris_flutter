import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Menampilkan bottom sheet berisi kolom komentar.
///
/// Mengembalikan teks komentar (sudah di-trim) kalau user menekan tombol
/// konfirmasi, atau null kalau dibatalkan. Kalau [required] false dan
/// komentar kosong, yang dikembalikan string kosong.
Future<String?> showCommentSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  required Color color,
  IconData icon = Icons.chat_bubble_outline,
  bool required = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    // Transparan: latar putih dan sudut membulat digambar sendiri di bawah,
    // supaya tidak kena tint hijau bawaan Material 3.
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentSheet(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      color: color,
      icon: icon,
      required: required,
    ),
  );
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.color,
    required this.icon,
    required this.required,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final Color color;
  final IconData icon;
  final bool required;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Saat keyboard terbuka, ikuti tinggi keyboard; kalau tidak, hormati
    // area aman di bawah (home indicator).
    final bottomInset =
        media.viewInsets.bottom > 0 ? media.viewInsets.bottom : media.padding.bottom;

    // Warna tombol terang (kuning/emas) butuh teks gelap supaya terbaca.
    final onColor =
        widget.color.computeLuminance() > 0.3 ? AppColors.text : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header: ikon + judul + deskripsi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(36),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Label kolom
            Text.rich(
              TextSpan(
                text: 'Comment',
                children: [
                  if (widget.required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.rejected),
                    )
                  else
                    TextSpan(
                      text: '  (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _controller,
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.all(14),
                border: _border(Colors.transparent),
                enabledBorder: _border(Colors.transparent),
                focusedBorder: _border(widget.color, width: 1.5),
                errorBorder: _border(AppColors.rejected),
                focusedErrorBorder: _border(AppColors.rejected, width: 1.5),
                errorStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.rejected,
                ),
              ),
              validator: (v) =>
                  widget.required && (v == null || v.trim().isEmpty)
                      ? 'Comment is required'
                      : null,
            ),
            const SizedBox(height: 18),

            // Tombol
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMid,
                      side: BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: onColor,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(widget.confirmLabel),
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
