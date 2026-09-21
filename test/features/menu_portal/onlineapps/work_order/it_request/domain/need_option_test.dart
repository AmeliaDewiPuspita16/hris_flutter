import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/need_option.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/request_category.dart';

void main() {
  NeedOption itOption(String id) =>
      NeedOptionCatalog.optionsFor(RequestCategory.it).firstWhere((o) => o.id == id);
  NeedOption mediaOption(String id) =>
      NeedOptionCatalog.optionsFor(RequestCategory.media).firstWhere((o) => o.id == id);

  group('requestCategoryCode — dipakai sebagai field request_category', () {
    test('sembilan opsi IT punya sembilan kode unik', () {
      final codes = NeedOptionCatalog.optionsFor(RequestCategory.it)
          .map((o) => o.requestCategoryCode)
          .toSet();

      expect(codes, {
        'new_account_req',
        'account_mgmt_req',
        'internet_req',
        'backup_req',
        'download_req',
        'perangkat_komputer_req',
        'event_equipment_req',
        'new_employee_req',
        'other_req',
      });
    });

    test('lima opsi Media punya kode yang benar, "Others" berbagi other_req', () {
      final codes = NeedOptionCatalog.optionsFor(RequestCategory.media)
          .map((o) => o.requestCategoryCode)
          .toList();

      expect(codes, [
        'desain_req',
        'dokumentasi_req',
        'printing_req',
        'social_media_req',
        'other_req',
      ]);
    });

    test('gabungan IT + Media menghasilkan 13 kode unik sesuai dokumentasi', () {
      final all = {
        ...NeedOptionCatalog.optionsFor(RequestCategory.it).map((o) => o.requestCategoryCode),
        ...NeedOptionCatalog.optionsFor(RequestCategory.media).map((o) => o.requestCategoryCode),
      };

      expect(all, hasLength(13));
    });
  });

  group('checkboxFieldCodes — sejajar urutannya dengan checkboxLabels', () {
    test('account_creation', () {
      final option = itOption('account_creation');

      expect(option.checkboxLabels, [
        'Email',
        'BIIE Portal account',
        'Synology Drive account',
        'Tenant Feedback account',
      ]);
      expect(option.checkboxFieldCodes, [
        'new_account_need_email',
        'new_account_need_portal',
        'new_account_need_synology',
        'new_account_need_tenant_feedback',
      ]);
    });

    test('account_mgmt', () {
      final option = itOption('account_mgmt');

      expect(option.checkboxFieldCodes, [
        'account_mgmt_need_new_username',
        'account_mgmt_need_password_reset',
        'account_mgmt_need_permission_change',
        'account_mgmt_need_deactivate',
      ]);
    });

    test('hardware', () {
      final option = itOption('hardware');

      expect(option.checkboxFieldCodes, [
        'hardware_need_laptop',
        'hardware_need_pc',
        'hardware_need_printer',
        'hardware_need_mouse',
      ]);
    });

    test('event_setup', () {
      final option = itOption('event_setup');

      expect(option.checkboxFieldCodes, [
        'event_equipment_need_projector',
        'event_equipment_need_pointer',
        'event_equipment_need_videotron',
        'event_equipment_need_webcam',
      ]);
    });

    test('opsi tanpa checkbox punya checkboxFieldCodes kosong', () {
      expect(itOption('internet_access').checkboxFieldCodes, isEmpty);
    });
  });

  group('textFieldCode — nama field untuk isian bebas', () {
    test('download_install mengirim ke download_desc', () {
      expect(itOption('download_install').textFieldCode, 'download_desc');
    });

    test('Others (IT maupun Media) mengirim ke other_desc', () {
      expect(itOption('others').textFieldCode, 'other_desc');
      expect(mediaOption('others').textFieldCode, 'other_desc');
    });

    test('opsi bukan textField punya textFieldCode null', () {
      expect(itOption('hardware').textFieldCode, isNull);
    });
  });
}
