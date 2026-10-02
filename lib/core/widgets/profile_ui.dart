import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Komponen kecil yang dipakai bersama oleh halaman-halaman di bawah Profil
/// (Data Diri, Kontrak Kerja, Rekening Bank, Alamat, Tanggungan).

/// Label bagian: huruf kapital kecil, mis. "IDENTITAS".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6),
      ),
    );
  }
}

/// Pil kecil berisi ikon + teks, mis. "Hanya Baca" atau "2 orang".
class InfoPill extends StatelessWidget {
  const InfoPill(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Penanda "Hanya Baca" dengan ikon gembok (menggantikan emoji).
class ReadOnlyBadge extends StatelessWidget {
  const ReadOnlyBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      const InfoPill('Hanya Baca', icon: Icons.lock_outline);
}

/// Catatan kaki berupa kotak info tipis berwarna hijau muda.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

/// Ikon dalam kotak bersudut membulat dengan latar hijau muda.
class TintedIcon extends StatelessWidget {
  const TintedIcon(this.icon, {super.key, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.primary),
    );
  }
}

/// Tombol pil kecil ("Ubah" / "Simpan") untuk baris yang bisa diedit.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed, this.filled = false});

  final String label;
  final VoidCallback onPressed;

  /// true = hijau pekat (aksi menyimpan), false = hijau muda (aksi mengubah).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      backgroundColor: WidgetStatePropertyAll(
        filled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.10),
      ),
      foregroundColor: WidgetStatePropertyAll(filled ? Colors.white : AppColors.primary),
    );
    final text = Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));
    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : TextButton(onPressed: onPressed, style: style, child: text);
  }
}
