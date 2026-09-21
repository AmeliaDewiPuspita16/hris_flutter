import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/new_employee_data.dart';
import 'package:hris_mobile/features/shared/domain/department.dart';

void main() {
  group('NewEmployeeEquipment.fieldCodes', () {
    test('memetakan tiap label ke nama field multipart', () {
      expect(
        NewEmployeeEquipment.fieldCodes[NewEmployeeEquipment.laptop],
        'new_employee_need_laptop',
      );
      expect(
        NewEmployeeEquipment.fieldCodes[NewEmployeeEquipment.email],
        'new_employee_need_email',
      );
      expect(
        NewEmployeeEquipment.fieldCodes[NewEmployeeEquipment.biiePortal],
        'new_employee_need_portal',
      );
      expect(
        NewEmployeeEquipment.fieldCodes[NewEmployeeEquipment.synologyDrive],
        'new_employee_need_synology',
      );
    });

    test('satu kode per label di NewEmployeeEquipment.all', () {
      expect(NewEmployeeEquipment.fieldCodes.length, NewEmployeeEquipment.all.length);
    });
  });

  group('NewEmployeeData', () {
    const department = Department(id: 1, name: 'AML');

    test('isComplete butuh department dari daftar server, bukan enum lokal', () {
      final complete = const NewEmployeeData(
        fullName: 'Andi Pratama',
        employeeNumber: 'EMP-2041',
        executiveType: ExecutiveType.nonExecutive,
      ).copyWith(department: department);

      expect(complete.isComplete, isTrue);
    });

    test('isComplete false selama department belum dipilih', () {
      const data = NewEmployeeData(
        fullName: 'Andi Pratama',
        employeeNumber: 'EMP-2041',
        executiveType: ExecutiveType.nonExecutive,
      );

      expect(data.isComplete, isFalse);
    });

    test('copyWith mengganti department dengan department server', () {
      const data = NewEmployeeData();

      final updated = data.copyWith(department: department);

      expect(updated.department, department);
    });
  });
}
