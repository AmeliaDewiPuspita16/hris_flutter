import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';

/// Isi sementara untuk tab yang kontennya belum dibuat ("Pending Vehicle
/// Assignment" dan "Supervisor Approval"). Diganti widget asli begitu
/// desain tab-nya ada.
class IndentTabPlaceholder extends StatelessWidget {
  const IndentTabPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title belum tersedia', style: AppTextStyles.bodyMuted),
    );
  }
}
