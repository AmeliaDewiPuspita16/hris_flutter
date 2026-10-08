import 'indent_approval_item.dart';

/// Data contoh tab "Supervisor Approval". Di screenshot web tabelnya kosong,
/// jadi isinya dikarang untuk menguji tampilan. Nanti diganti API.
class IndentApprovalDemoData {
  IndentApprovalDemoData._();

  static List<IndentApprovalItem> items() => const [
        IndentApprovalItem(
          id: 'approval-1',
          name: 'Cahyo Jati Nugroho',
          destination: 'Bionesia',
          date: '10-10-2026',
          timeRange: '10:00:00 s/d 13:00:00',
          remark: 'pengecekan legal compliance Bionesia',
          withDriver: true,
        ),
        IndentApprovalItem(
          id: 'approval-2',
          name: 'Tanjelia Jissi',
          destination: 'Kawasan',
          date: '10-10-2026',
          timeRange: '13:00:00 s/d 15:00:00',
          remark: 'Meeting with Prodia',
          withDriver: false,
        ),
        IndentApprovalItem(
          id: 'approval-3',
          name: 'Putri Afifah Yasmine',
          destination: 'RS Busung',
          date: '11-10-2026',
          timeRange: '08:30:00 s/d 10:00:00',
          remark: 'Antar Vale',
          withDriver: true,
        ),
      ];
}
