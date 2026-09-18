import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_line_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition.dart';

void main() {
  PrLineItem line({int qty = 1, int estPrice = 1000}) => PrLineItem(
        description: 'Tisu evo napkin luncheon 100\'s',
        kind: PrItemKind.goods,
        qty: qty,
        unit: 'BOX',
        estPrice: estPrice,
      );

  PurchaseRequisition requisition({
    String prNumber = 'PR/EVD/26-09/10',
    String requestor = 'Rindiani',
    String purpose = 'operational Restaurant',
    List<PrLineItem>? items,
  }) =>
      PurchaseRequisition(
        id: 'pr-1',
        prNumber: prNumber,
        date: DateTime(2026, 9, 18),
        department: 'EVD',
        section: 'F&B Service',
        requestor: requestor,
        requiredDate: DateTime(2026, 9, 17),
        purpose: purpose,
        status: PrStatus.pendingHod,
        items: items ?? [line()],
      );

  group('PrLineItem', () {
    test('subtotal adalah qty dikali harga satuan', () {
      expect(line(qty: 5, estPrice: 453000).subtotal, 2265000);
    });
  });

  group('PurchaseRequisition', () {
    test('estimatedTotal menjumlahkan subtotal seluruh item', () {
      final pr = requisition(
        items: [line(qty: 5, estPrice: 453000), line(qty: 2, estPrice: 100000)],
      );

      expect(pr.estimatedTotal, 2465000);
    });

    test('itemCount mengikuti jumlah baris item', () {
      expect(requisition(items: [line(), line(), line()]).itemCount, 3);
    });

    test('itemCountLabel memakai bentuk tunggal untuk satu item', () {
      expect(requisition(items: [line()]).itemCountLabel, '1 item');
    });

    test('itemCountLabel memakai bentuk jamak untuk lebih dari satu item', () {
      expect(requisition(items: [line(), line()]).itemCountLabel, '2 items');
    });
  });

  group('PurchaseRequisition.matchesQuery', () {
    test('cocok lewat nomor PR tanpa peduli besar kecil huruf', () {
      expect(requisition().matchesQuery('evd/26-09'), isTrue);
    });

    test('cocok lewat nama requestor', () {
      expect(requisition(requestor: 'Darmawati').matchesQuery('darma'), isTrue);
    });

    test('cocok lewat purpose', () {
      expect(requisition(purpose: 'Pengecatan Studio 2C').matchesQuery('studio'), isTrue);
    });

    test('tidak cocok bila kata kunci tidak ada di ketiga kolom itu', () {
      expect(requisition().matchesQuery('forklift'), isFalse);
    });

    test('query kosong dianggap cocok dengan semua PR', () {
      expect(requisition().matchesQuery('   '), isTrue);
    });
  });
}
