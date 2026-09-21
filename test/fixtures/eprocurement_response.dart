/// Contoh respons `GET /api/portal/apps/eprocurement` dan
/// `GET /api/portal/apps/eprocurement/{id}`, disalin dari respons sungguhan.
///
/// Perhatikan dua hal yang membedakannya dari endpoint lain: amplop daftar
/// menaruh `summary`, `scope`, dan `meta` BERSEBELAHAN dengan `data`, dan
/// endpoint daftar tidak mengirim `items` sama sekali — hanya `items_count`
/// dan `total_estimated_amount`.
library;

Map<String, dynamic> eprocurementListEnvelope({
  List<Map<String, dynamic>>? items,
  Map<String, int>? summary,
  int currentPage = 1,
  int lastPage = 1,
  int perPage = 20,
  int total = 9,
}) {
  return {
    'data': items ?? [eprocurementListItem()],
    'summary': summary ??
        {
          'all': 9,
          'pending_hod': 1,
          'pending_review': 3,
          'pending_dgm': 0,
          'pending_finance': 1,
          'pending_gm': 2,
          'draft': 0,
          'under_revision': 0,
          'approved': 1,
          'rejected': 0,
          'po_created': 1,
        },
    'scope': {'sees_all_departments': true, 'department': null},
    'meta': {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    },
  };
}

Map<String, dynamic> eprocurementListItem({
  int id = 9,
  String prNumber = 'PR/AML/26-09/01',
  String prDate = '2026-09-01',
  String section = 'Admin Legal',
  String requestor = 'Rika Susila Susanti',
  String purpose = 'Retribusi Persetujuan Bangunan Gedung (PBG)',
  int itemsCount = 1,
  int totalEstimatedAmount = 2938005000,
  String statusCode = 'pending_review',
  String statusLabel = 'Pending Review',
  int? level = 2,
}) {
  return {
    'id': id,
    'pr_number': prNumber,
    'pr_date': prDate,
    'section': section,
    'requestor': requestor,
    'purpose': purpose,
    'items_count': itemsCount,
    'total_estimated_amount': totalEstimatedAmount,
    'currency': 'IDR',
    'status': {'code': statusCode, 'label': statusLabel, 'level': level},
  };
}

/// Detail PR/HSE/26-08/01: lampiran terisi, tahap approval bercampur
/// (approved / waiting / pending), dokumen baru berjalan di tahap pertama.
Map<String, dynamic> eprocurementDetail({
  int id = 3,
  String prNumber = 'PR/HSE/26-08/01',
  String statusCode = 'pending_finance',
  String statusLabel = 'Pending Finance Manager',
  String? rejectionReason,
  String? revisionNotes,
  String? approvedAt,
  List<Map<String, dynamic>>? items,
  List<Map<String, dynamic>>? attachments,
  List<Map<String, dynamic>>? approvalProgress,
  List<Map<String, dynamic>>? documentProgress,
}) {
  return {
    'id': id,
    'pr_number': prNumber,
    'pr_date': '2026-08-28',
    'section': 'Sustainability Performance Engineer',
    'requestor': 'Sarla Intan Cahyani',
    'purpose': 'Perbaikan Excavator Bomac akibat kerusakan house neeple',
    'items_count': 3,
    'attachments_count': 3,
    'total_estimated_amount': 6900000,
    'currency': 'IDR',
    'status': {'code': statusCode, 'label': statusLabel, 'level': 4},
    'required_date': '2026-09-03',
    'department': 'HSE',
    'priority': 'normal',
    'paper_ref': null,
    'revision_notes': revisionNotes,
    'rejection_reason': rejectionReason,
    'submitted_at': '2026-08-28T15:03:11+07:00',
    'approved_at': approvedAt,
    'items': items ??
        [
          {
            'line_number': 1,
            'item_type': 'service',
            'description': 'Bongkar dan pasang boom silinder arm excavator',
            'specification': null,
            'quantity': 1,
            'uom': 'set',
            'unit_price': 3000000,
            'total_price': 3000000,
            'gl_account': '513110',
            'segment': 'SVC - MAINT',
            'notes': null,
          },
          {
            'line_number': 3,
            'item_type': 'goods',
            'description': 'Oli Hydraulic SAE 46 @20L',
            'specification': null,
            'quantity': 1,
            'uom': 'pcs',
            'unit_price': 1400000,
            'total_price': 1400000,
            'gl_account': '513110',
            'segment': 'SVC - MAINT',
            'notes': null,
          },
        ],
    'attachments': attachments ??
        [
          {
            'id': 2,
            'is_link': false,
            'label': 'Attachment perbaikan excavator.pdf',
            'category': 'supporting_doc',
            'url': 'https://biieportal.co.id/storage/epro/attachments/6by4.pdf',
            'file_name': 'Attachment perbaikan excavator.pdf',
            'file_type': 'application/pdf',
            'file_size': 398915,
            'size_label': '389.57 KB',
            'uploaded_at': '2026-08-28T10:59:15+07:00',
          },
        ],
    'approval_progress': approvalProgress ??
        [
          {
            'level': 1,
            'label': 'HOD',
            'subtitle': 'Head of Department',
            'state': 'approved',
            'state_label': 'Disetujui',
            'approver': 'Habib Twindy Lubis',
            'comments': null,
            'acted_at': '2026-08-28T15:03:43+07:00',
          },
          {
            'level': 4,
            'label': 'Finance Manager',
            'subtitle': 'Finance Manager',
            'state': 'waiting',
            'state_label': 'Menunggu persetujuan',
            'approver': null,
            'comments': null,
            'acted_at': null,
          },
          {
            'level': 5,
            'label': 'GM',
            'subtitle': 'General Manager',
            'state': 'pending',
            'state_label': 'Belum diproses',
            'approver': null,
            'comments': null,
            'acted_at': null,
          },
        ],
    'document_progress': documentProgress ??
        [
          {
            'code': 'pr_approval',
            'label': 'PR Approval',
            'state': 'in_progress',
            'count': null,
          },
          {
            'code': 'vendor_tally',
            'label': 'Vendor Tally',
            'state': 'not_started',
            'count': 0,
            'numbers': <String>[],
          },
          {
            'code': 'purchase_order',
            'label': 'Purchase Order',
            'state': 'done',
            'count': 1,
            'numbers': ['BIIE/26-08-003'],
          },
        ],
  };
}
