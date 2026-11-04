import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// FAB "buat proyek". [onPressed] null = nonaktif (form proyek belum
/// tersambung).
class EstCreateProjectFab extends StatelessWidget {
  const EstCreateProjectFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.solid(AppColors.orange),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
