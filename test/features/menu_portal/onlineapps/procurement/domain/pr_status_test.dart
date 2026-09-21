import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';

void main() {
  group('PrStatusCode', () {
    test('mengenali sepuluh kode yang dikirim server', () {
      expect(
        PrStatusCode.values.map((c) => c.code).toList(),
        const [
          'pending_hod',
          'pending_review',
          'pending_dgm',
          'pending_finance',
          'pending_gm',
          'draft',
          'under_revision',
          'approved',
          'rejected',
          'po_created',
        ],
      );
    });

    test('mengembalikan null untuk kode yang belum dikenal', () {
      expect(PrStatusCode.fromCode('menunggu_direksi'), isNull);
    });
  });

  group('PrStatus.fromJson', () {
    test('memakai label dari server apa adanya', () {
      final status = PrStatus.fromJson(const {
        'code': 'pending_finance',
        'label': 'Pending Finance Manager',
        'level': 4,
      });

      expect(status.code, 'pending_finance');
      expect(status.label, 'Pending Finance Manager');
      expect(status.level, 4);
    });

    test('kode baru dari server tetap tampil, tidak digugurkan', () {
      final status = PrStatus.fromJson(const {
        'code': 'menunggu_direksi',
        'label': 'Menunggu Direksi',
      });

      expect(status.label, 'Menunggu Direksi');
      expect(status.color, AppColors.neutral);
    });

    test('status yang hilang sama sekali tidak bikin layar kosong', () {
      final status = PrStatus.fromJson(null);

      expect(status.code, isEmpty);
      expect(status.label, 'Tidak diketahui');
    });

    test('label kosong jatuh ke label pendek kode yang dikenal', () {
      final status = PrStatus.fromJson(const {'code': 'po_created', 'label': ''});

      expect(status.label, 'PO Created');
    });
  });

  group('PrStatus', () {
    PrStatus statusOf(String code) =>
        PrStatus.fromJson({'code': code, 'label': code});

    test('semua tahap approval ditandai masih berjalan', () {
      expect(statusOf('pending_hod').isPending, isTrue);
      expect(statusOf('pending_gm').isPending, isTrue);
      expect(statusOf('approved').isPending, isFalse);
      expect(statusOf('rejected').isPending, isFalse);
    });

    test('selesai, ditolak, dan menunggu punya warna yang berbeda', () {
      expect(statusOf('approved').color, AppColors.present);
      expect(statusOf('rejected').color, AppColors.rejected);
      expect(statusOf('pending_hod').color, AppColors.pending);
      expect(statusOf('po_created').color, AppColors.teal);
    });

    test('shortLabel dipakai chip filter supaya muat berdampingan', () {
      expect(statusOf('pending_finance').shortLabel, 'Finance');
      expect(statusOf('under_revision').shortLabel, 'Revisi');
    });

    test('shortLabel kode tak dikenal jatuh ke label servernya', () {
      final status = PrStatus.fromJson(const {
        'code': 'menunggu_direksi',
        'label': 'Menunggu Direksi',
      });

      expect(status.shortLabel, 'Menunggu Direksi');
    });
  });
}
