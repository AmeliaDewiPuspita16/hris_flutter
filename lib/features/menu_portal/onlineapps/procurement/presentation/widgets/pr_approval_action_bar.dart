import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Bar aksi yang menempel di bawah layar detail PR.
///
/// Latarnya gradient yang memudar dari transparan ke warna background layar,
/// jadi konten di belakang bar hilang perlahan tanpa garis pemisah. Tombol
/// Reject dan Revisi berisi putih supaya konten di belakangnya tidak tembus.
///
/// Selama [enabled] false, semua tombol mati dan muncul petunjuk yang bisa
/// diketuk ([onLockedTap]) untuk menggulung layar ke bawah.
class PrApprovalActionBar extends StatelessWidget {
  const PrApprovalActionBar({
    super.key,
    required this.onApprove,
    required this.onRevision,
    required this.onReject,
    this.isLoading = false,
    this.enabled = true,
    this.onLockedTap,
  });

  final VoidCallback onApprove;
  final VoidCallback onRevision;
  final VoidCallback onReject;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onLockedTap;

  static const _red = AppColors.rejected;
  static const _amber = AppColors.accent;
  // Emas lebih gelap khusus teks, karena AppColors.accent di atas putih kurang terbaca.
  static const _amberText = Color(0xFF8F6F1E);
  static const _green = AppColors.primary;
  static const _disabledBorder = Color(0xFFD9D8D2);

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withAlpha(0),
            AppColors.bg.withAlpha(235),
            AppColors.bg.withAlpha(250),
          ],
          // Bagian atas (~30%) adalah zona memudar, sisanya hampir pekat.
          stops: const [0, 0.3, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Padding atas yang besar = ruang untuk zona memudar.
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: enabled
                    ? const SizedBox(width: double.infinity)
                    : InkWell(
                        onTap: onLockedTap,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_double_arrow_down,
                                size: 16,
                                color: AppColors.textMid,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Scroll to the bottom to enable the buttons',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: active ? onReject : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.black26,
                        foregroundColor: _red,
                        side: BorderSide(
                          color: active ? _red : _disabledBorder,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: active ? onRevision : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.black26,
                        foregroundColor: _amberText,
                        side: BorderSide(
                          color: active ? _amber : _disabledBorder,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Revision',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: active ? onApprove : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: _green,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Approve',
                              maxLines: 1,
                              softWrap: false,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
