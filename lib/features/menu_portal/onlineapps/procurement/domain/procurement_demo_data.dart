import 'approval_step.dart';
import 'document_stage.dart';
import 'pr_attachment.dart';
import 'pr_line_item.dart';
import 'pr_status.dart';
import 'progress_state.dart';
import 'purchase_requisition.dart';

/// Data contoh Purchase Requisition, pola sama dengan [ListRequestDemoData]
/// di IT Request — dipakai sampai endpoint EProcurement tersedia.
///
/// Tiap PR cukup menyebut sudah sampai tahap approval ke berapa (`stage`);
/// status, daftar Approval Progress, dan Progress Dokumen diturunkan dari
/// situ supaya ketiganya tidak mungkin saling bertentangan.
class ProcurementDemoData {
  ProcurementDemoData._();

  /// Urutan rantai approval PR. Indeksnya dipakai sebagai `stage`.
  static const _approvalChain = [
    (title: 'HOD Approval', short: 'HOD'),
    (title: 'Under Review Approval', short: 'Under Review'),
    (title: 'DGM Approval', short: 'DGM'),
    (title: 'Finance Manager Approval', short: 'Finance Manager'),
    (title: 'GM Approval', short: 'GM'),
  ];

  /// `stage` sebesar panjang rantai berarti seluruh tahap sudah lewat.
  static const _approvedStage = 5;

  static List<PurchaseRequisition> items() => [
        _build(
          id: 'pr-evd-10',
          prNumber: 'PR/EVD/26-09/10',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 17),
          department: 'EVD',
          section: 'F&B Service',
          requestor: 'Rindiani',
          purpose: 'operational Restaurant',
          stage: 0,
          items: const [
            PrLineItem(
              description: "Tisu evo napkin luncheon 100's",
              kind: PrItemKind.goods,
              qty: 5,
              unit: 'BOX',
              estPrice: 453000,
            ),
          ],
          attachments: const [
            PrAttachment(
              fileName: "Tisu evo napkin luncheon 100's.xlsx",
              sizeLabel: '720.94 KB',
            ),
          ],
        ),
        _build(
          id: 'pr-evd-09',
          prNumber: 'PR/EVD/26-09/09',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 20),
          department: 'EVD',
          section: 'F&B Product',
          requestor: 'Rindiani',
          purpose: 'uniform warung prasmanan selera kita',
          stage: 0,
          items: const [
            PrLineItem(
              description: 'Kemeja seragam prasmanan',
              kind: PrItemKind.goods,
              qty: 12,
              unit: 'PCS',
              estPrice: 185000,
            ),
            PrLineItem(
              description: 'Celemek kain drill',
              kind: PrItemKind.goods,
              qty: 12,
              unit: 'PCS',
              estPrice: 75000,
            ),
          ],
        ),
        _build(
          id: 'pr-evd-08',
          prNumber: 'PR/EVD/26-09/08',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 25),
          department: 'EVD',
          section: 'Maintenance',
          requestor: 'Rindiani',
          purpose: 'Pergantian net tenis lapangan dikarenakan yg lama sudah rusak',
          stage: 0,
          items: const [
            PrLineItem(
              description: 'Net lapangan tenis standar',
              kind: PrItemKind.goods,
              qty: 2,
              unit: 'UNIT',
              estPrice: 1250000,
            ),
          ],
        ),
        _build(
          id: 'pr-est-13',
          prNumber: 'PR/EST/26-09/13',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 24),
          department: 'EST',
          section: 'Estate Admin Asssitant',
          requestor: 'Darmawati',
          purpose: 'Melakukan maintenance unit Forklif Power House',
          stage: 2,
          items: const [
            PrLineItem(
              description: 'Jasa service berkala forklift',
              kind: PrItemKind.service,
              glAccount: '6210-0031',
              qty: 1,
              unit: 'JOB',
              estPrice: 4750000,
            ),
            PrLineItem(
              description: 'Filter hidrolik forklift',
              kind: PrItemKind.goods,
              glAccount: '6210-0031',
              qty: 2,
              unit: 'PCS',
              estPrice: 385000,
            ),
          ],
          attachments: const [
            PrAttachment(
              fileName: 'Penawaran maintenance forklift.pdf',
              sizeLabel: '312.40 KB',
            ),
          ],
        ),
        _build(
          id: 'pr-est-12',
          prNumber: 'PR/EST/26-09/12',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 30),
          department: 'EST',
          section: 'Maintenance & Building Tenancy Section Head',
          requestor: 'Yason',
          purpose: 'Pengecatan Studio 2C BIEV',
          stage: 2,
          items: const [
            PrLineItem(
              description: 'Cat tembok interior 25 kg',
              kind: PrItemKind.goods,
              qty: 4,
              unit: 'PAIL',
              estPrice: 875000,
            ),
            PrLineItem(
              description: 'Jasa pengecatan studio',
              kind: PrItemKind.service,
              qty: 1,
              unit: 'JOB',
              estPrice: 6500000,
            ),
          ],
        ),
        _build(
          id: 'pr-hse-05',
          prNumber: 'PR/HSE/26-09/05',
          date: DateTime(2026, 9, 18),
          requiredDate: DateTime(2026, 9, 22),
          department: 'HSE',
          section: 'Hygiene Sanitation & Vector Control',
          requestor: 'Dini Dwi Pratiwi',
          purpose: 'untuk drill injeksi rayap di blok 5B unit 1-8',
          stage: 0,
          items: const [
            PrLineItem(
              description: 'Mata bor beton 12 mm',
              kind: PrItemKind.goods,
              qty: 8,
              unit: 'PCS',
              estPrice: 65000,
            ),
            PrLineItem(
              description: 'Termitisida konsentrat 1 L',
              kind: PrItemKind.goods,
              qty: 8,
              unit: 'BTL',
              estPrice: 420000,
            ),
          ],
        ),
        _build(
          id: 'pr-cvl-02',
          prNumber: 'PR/CVL/26-09/02',
          date: DateTime(2026, 9, 17),
          requiredDate: DateTime(2026, 9, 19),
          department: 'CVL',
          section: 'Civil Engineer Executive',
          requestor: 'Diko Despabera',
          purpose: 'Tambahan material pekerjaan drainase Prodia',
          stage: _approvedStage,
          items: const [
            PrLineItem(
              description: 'Semen PCC 50 kg',
              kind: PrItemKind.goods,
              glAccount: '6110-0012',
              qty: 40,
              unit: 'SAK',
              estPrice: 62000,
            ),
          ],
          attachments: const [
            PrAttachment(fileName: 'RAB drainase Prodia.xlsx', sizeLabel: '96.20 KB'),
          ],
        ),
      ];

  static PurchaseRequisition _build({
    required String id,
    required String prNumber,
    required DateTime date,
    required DateTime requiredDate,
    required String department,
    required String section,
    required String requestor,
    required String purpose,
    required int stage,
    required List<PrLineItem> items,
    List<PrAttachment> attachments = const [],
  }) {
    return PurchaseRequisition(
      id: id,
      prNumber: prNumber,
      date: date,
      department: department,
      section: section,
      requestor: requestor,
      requiredDate: requiredDate,
      purpose: purpose,
      status: _statusAt(stage),
      items: items,
      attachments: attachments,
      approvalSteps: _approvalStepsAt(stage),
      documentStages: _documentStagesAt(stage),
    );
  }

  static PrStatus _statusAt(int stage) => switch (stage) {
        0 => PrStatus.pendingHod,
        1 => PrStatus.pendingUnderReview,
        2 => PrStatus.pendingDgm,
        3 => PrStatus.pendingFinance,
        4 => PrStatus.pendingGm,
        _ => PrStatus.prApproved,
      };

  static ProgressState _stateAt(int index, int stage) {
    if (index < stage) return ProgressState.done;
    if (index == stage) return ProgressState.current;
    return ProgressState.pending;
  }

  static String _noteFor(ProgressState state) => switch (state) {
        ProgressState.done => 'Disetujui',
        ProgressState.current => 'Menunggu persetujuan',
        ProgressState.pending => 'Belum diproses',
      };

  static List<ApprovalStep> _approvalStepsAt(int stage) => [
        for (var i = 0; i < _approvalChain.length; i++)
          ApprovalStep(
            title: _approvalChain[i].title,
            note: _noteFor(_stateAt(i, stage)),
            state: _stateAt(i, stage),
          ),
      ];

  static List<DocumentStage> _documentStagesAt(int stage) {
    final approved = stage >= _approvedStage;

    return [
      DocumentStage(
        title: 'PR Approval',
        statusLabel: approved ? 'Selesai' : 'Sedang Berjalan',
        state: approved ? ProgressState.done : ProgressState.current,
        subSteps: [
          for (var i = 0; i < _approvalChain.length; i++)
            DocumentSubStep(
              label: _approvalChain[i].short,
              state: _stateAt(i, stage),
              // Tahap yang belum diproses dibiarkan tanpa keterangan, sama
              // seperti di web — cukup nama tahapnya saja.
              note: _stateAt(i, stage) == ProgressState.pending
                  ? null
                  : _noteFor(_stateAt(i, stage)),
            ),
        ],
      ),
      DocumentStage(
        title: 'Vendor Tally',
        statusLabel: approved ? 'Sedang Berjalan' : 'Belum dibuat',
        state: approved ? ProgressState.current : ProgressState.pending,
      ),
      const DocumentStage(
        title: 'Purchase Order',
        statusLabel: 'Belum dibuat',
        state: ProgressState.pending,
      ),
      const DocumentStage(
        title: 'Goods Receipt',
        statusLabel: 'Belum ada',
        state: ProgressState.pending,
      ),
    ];
  }
}
