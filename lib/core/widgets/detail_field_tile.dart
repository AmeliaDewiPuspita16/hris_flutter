import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Satu baris "label : value" read-only. Dipakai berulang di layar-layar
/// detail Profil (Kontrak, Rekening, Alamat) supaya tidak duplikasi kode.
class DetailFieldTile extends StatelessWidget {
  const DetailFieldTile({super.key, required this.label, required this.value, this.showDivider = true});

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}