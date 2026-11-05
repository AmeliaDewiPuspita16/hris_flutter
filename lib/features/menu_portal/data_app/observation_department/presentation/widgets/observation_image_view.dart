import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Menampilkan foto temuan / foto penutupan. [source] bisa URL (http...)
/// atau path file lokal; null = placeholder "No photo". Ketuk foto untuk
/// memperbesar.
class ObservationImageView extends StatelessWidget {
  const ObservationImageView({super.key, required this.source, this.height = 200});

  final String? source;
  final double height;

  bool get _isUrl => source != null && source!.startsWith('http');

  Widget _image({BoxFit fit = BoxFit.cover}) {
    final error = _Placeholder(
      icon: Icons.broken_image_outlined,
      text: 'Photo unavailable',
      height: height,
    );
    return _isUrl
        ? Image.network(source!, fit: fit, errorBuilder: (_, __, ___) => error)
        : Image.file(File(source!), fit: fit, errorBuilder: (_, __, ___) => error);
  }

  @override
  Widget build(BuildContext context) {
    if (source == null || source!.isEmpty) {
      return _Placeholder(
        icon: Icons.image_not_supported_outlined,
        text: 'No photo',
        height: height,
      );
    }

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: _image(fit: BoxFit.contain)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: _image(),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.text,
    required this.height,
  });

  final IconData icon;
  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: AppColors.textMuted),
          const SizedBox(height: 6),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
