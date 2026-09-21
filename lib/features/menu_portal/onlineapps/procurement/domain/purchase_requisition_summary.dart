import '../../../../../core/utils/json_value.dart';
import 'pr_status.dart';

/// Satu PR sebagaimana dikirim endpoint daftar.
///
/// Sengaja terpisah dari [PurchaseRequisition]: endpoint daftar tidak
/// mengirim `items` sama sekali — hanya `items_count` dan
/// `total_estimated_amount` — jadi model daftar tidak boleh berpura-pura
/// punya rincian item.
class PurchaseRequisitionSummary {
  const PurchaseRequisitionSummary({
    required this.id,
    required this.prNumber,
    required this.prDate,
    required this.section,
    required this.requestor,
    required this.purpose,
    required this.itemsCount,
    required this.totalEstimatedAmount,
    required this.currency,
    required this.status,
  });

  final int id;

  /// Ex: "PR/AML/26-09/01".
  final String prNumber;

  final DateTime prDate;
  final String section;
  final String requestor;
  final String purpose;
  final int itemsCount;

  /// Dari `total_estimated_amount` server.
  final int totalEstimatedAmount;

  /// Ex: "IDR". Sementara hanya Rupiah yang diformat; lihat `formatRupiah`.
  final String currency;

  final PrStatus status;

  /// Ex: "1 item", "8 items" — mengikuti badge jumlah item di web.
  String get itemCountLabel => itemsCount == 1 ? '1 item' : '$itemsCount items';

  /// Melempar [FormatException] bila id atau tanggalnya tidak terbaca.
  /// PR tanpa id tidak bisa dibuka detailnya, dan tanpa tanggal kartunya
  /// menyesatkan — lebih baik satu baris dilewati daripada salah tampil.
  factory PurchaseRequisitionSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons PR tidak memuat id');
    }

    final prDate = dateOrNull(json['pr_date']);
    if (prDate == null) {
      throw const FormatException('pr_date tidak bisa diurai');
    }

    return PurchaseRequisitionSummary(
      id: id,
      prNumber: '${json['pr_number'] ?? ''}',
      prDate: prDate,
      section: '${json['section'] ?? ''}',
      requestor: '${json['requestor'] ?? ''}',
      purpose: '${json['purpose'] ?? ''}',
      itemsCount: intOr(json['items_count'], 0),
      totalEstimatedAmount: amountOrZero(json['total_estimated_amount']),
      currency: '${json['currency'] ?? 'IDR'}',
      status: PrStatus.fromJson(
        json['status'] is Map<String, dynamic>
            ? json['status'] as Map<String, dynamic>
            : null,
      ),
    );
  }
}
