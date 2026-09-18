import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';

void main() {
  test('label mengikuti penamaan di web EProcurement', () {
    expect(PrStatus.pendingHod.label, 'Pending HOD');
    expect(PrStatus.pendingUnderReview.label, 'Pending Under Review');
    expect(PrStatus.pendingDgm.label, 'Pending DGM');
    expect(PrStatus.pendingFinance.label, 'Pending Finance Manager');
    expect(PrStatus.pendingGm.label, 'Pending GM');
    expect(PrStatus.prApproved.label, 'PR Approved');
    expect(PrStatus.rejected.label, 'Rejected');
  });

  test('semua tahap yang masih menunggu persetujuan bertanda pending', () {
    expect(
      PrStatus.values.where((s) => s.isPending).toList(),
      const [
        PrStatus.pendingHod,
        PrStatus.pendingUnderReview,
        PrStatus.pendingDgm,
        PrStatus.pendingFinance,
        PrStatus.pendingGm,
      ],
    );
  });

  test('PR selesai dan ditolak punya warna yang berbeda dari pending', () {
    expect(PrStatus.prApproved.color, AppColors.present);
    expect(PrStatus.rejected.color, AppColors.rejected);
    expect(PrStatus.pendingHod.color, AppColors.pending);
  });
}
