import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_status.dart';

void main() {
  group('ItRequestStatus.fromJson', () {
    test('memakai label dari server apa adanya', () {
      final status =
          ItRequestStatus.fromJson(const {'code': 'finished', 'label': 'Finished'});

      expect(status.code, 'finished');
      expect(status.label, 'Finished');
    });

    test('finished (sudah dinilai) berwarna hijau', () {
      final status =
          ItRequestStatus.fromJson(const {'code': 'finished', 'label': 'Finished'});

      expect(status.color, AppColors.present);
    });

    test('done (sudah dikerjakan, menunggu rating) berwarna aksen', () {
      final status = ItRequestStatus.fromJson(const {'code': 'done', 'label': 'Done'});

      expect(status.color, AppColors.accent);
    });

    test('kode yang belum dikenal tetap tampil, warnanya netral', () {
      // Kode selain "done"/"finished" belum ada contohnya — daripada
      // menebak warna yang salah, kode tak dikenal jatuh ke netral tapi
      // labelnya tetap dari server apa adanya.
      final status = ItRequestStatus.fromJson(
        const {'code': 'entah_apa', 'label': 'Entah Apa'},
      );

      expect(status.label, 'Entah Apa');
      expect(status.color, AppColors.neutral);
    });

    test('status yang hilang sama sekali tidak bikin layar kosong', () {
      final status = ItRequestStatus.fromJson(null);

      expect(status.code, isEmpty);
      expect(status.label, 'Tidak diketahui');
    });
  });
}
