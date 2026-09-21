import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/code_label.dart';

void main() {
  group('CodeLabel.fromJson', () {
    test('memetakan code dan label apa adanya', () {
      final value =
          CodeLabel.fromJson(const {'code': 'email_req', 'label': 'Email account'});

      expect(value.code, 'email_req');
      expect(value.label, 'Email account');
    });

    test('objek yang hilang jadi code & label kosong', () {
      final value = CodeLabel.fromJson(null);

      expect(value.code, isEmpty);
      expect(value.label, isEmpty);
    });
  });
}
