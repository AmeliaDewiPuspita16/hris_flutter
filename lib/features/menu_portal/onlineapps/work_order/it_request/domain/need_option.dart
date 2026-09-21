import 'request_category.dart';

/// Jenis field tambahan yang muncul di bawah satu opsi "What do you need?"
/// begitu opsi itu dipilih.
enum NeedFieldKind {
  /// Tidak ada field tambahan — Description langsung muncul.
  none,

  /// Grup checkbox singkat, mis. Laptop/PC/Printer/Mouse.
  checkboxGroup,

  /// Satu text field bebas, mis. "Specify application name".
  textField,

  /// Form khusus "New employee account creation" — dirender lewat widget
  /// `NewEmployeeSubform` tersendiri, bukan lewat [checkboxLabels]/[textHint].
  newEmployeeForm,
}

/// Satu opsi pada daftar "What do you need?", termasuk field tambahan yang
/// mungkin muncul di bawahnya saat dipilih.
class NeedOption {
  const NeedOption({
    required this.id,
    required this.label,
    required this.requestCategoryCode,
    this.fieldKind = NeedFieldKind.none,
    this.checkboxLabels = const [],
    this.checkboxFieldCodes = const [],
    this.textHint,
    this.textFieldCode,
  });

  /// ID stabil dipakai sebagai key penyimpanan state (checkbox terpilih,
  /// isi text field) di layar form — bukan untuk ditampilkan.
  final String id;
  final String label;

  /// Nilai `request_category` yang dikirim ke
  /// `POST /api/portal/apps/it_request` saat opsi ini yang dipilih.
  final String requestCategoryCode;

  final NeedFieldKind fieldKind;

  /// Dipakai kalau [fieldKind] == [NeedFieldKind.checkboxGroup].
  final List<String> checkboxLabels;

  /// Nama field multipart untuk tiap entri [checkboxLabels], urutannya
  /// sejajar — `checkboxFieldCodes[i]` adalah kode kirim untuk
  /// `checkboxLabels[i]`. Dipisah dari [checkboxLabels] (bukan digabung jadi
  /// satu record) supaya widget tampilan (`NeedChoiceChips`) tidak perlu
  /// tahu apa-apa soal nama field server.
  final List<String> checkboxFieldCodes;

  /// Dipakai kalau [fieldKind] == [NeedFieldKind.textField].
  final String? textHint;

  /// Nama field multipart untuk isian [textHint], ex: "download_desc".
  final String? textFieldCode;
}

/// Daftar opsi "What do you need?" untuk tiap [RequestCategory] — mengikuti
/// opsi pada form "Add Request" di versi web apa adanya. `requestCategoryCode`
/// dan field-field kirimnya mengikuti dokumentasi
/// `POST /api/portal/apps/it_request`.
class NeedOptionCatalog {
  NeedOptionCatalog._();

  static const _it = <NeedOption>[
    NeedOption(
      id: 'account_creation',
      label: 'Account creation',
      requestCategoryCode: 'new_account_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'Email',
        'BIIE Portal account',
        'Synology Drive account',
        'Tenant Feedback account',
      ],
      checkboxFieldCodes: [
        'new_account_need_email',
        'new_account_need_portal',
        'new_account_need_synology',
        'new_account_need_tenant_feedback',
      ],
    ),
    NeedOption(
      id: 'account_mgmt',
      label: 'Account management changes',
      requestCategoryCode: 'account_mgmt_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'New username',
        'Password reset',
        'Access Permission/Role Change',
        'Deactivate account',
      ],
      checkboxFieldCodes: [
        'account_mgmt_need_new_username',
        'account_mgmt_need_password_reset',
        'account_mgmt_need_permission_change',
        'account_mgmt_need_deactivate',
      ],
    ),
    NeedOption(
      id: 'internet_access',
      label: 'Internet / network access',
      requestCategoryCode: 'internet_req',
    ),
    NeedOption(
      id: 'backup_data',
      label: 'Backup data (weekly)',
      requestCategoryCode: 'backup_req',
    ),
    NeedOption(
      id: 'download_install',
      label: 'Download/install application',
      requestCategoryCode: 'download_req',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify application name',
      textFieldCode: 'download_desc',
    ),
    NeedOption(
      id: 'hardware',
      label: 'Computer/IT hardware (laptop, PC, printer, mouse)',
      requestCategoryCode: 'perangkat_komputer_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: ['Laptop', 'PC', 'Printer', 'Mouse'],
      checkboxFieldCodes: [
        'hardware_need_laptop',
        'hardware_need_pc',
        'hardware_need_printer',
        'hardware_need_mouse',
      ],
    ),
    NeedOption(
      id: 'event_setup',
      label: 'Setup Event/Meeting Equipment',
      requestCategoryCode: 'event_equipment_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: ['Projector', 'Pointer', 'Videotron', 'Webcam'],
      checkboxFieldCodes: [
        'event_equipment_need_projector',
        'event_equipment_need_pointer',
        'event_equipment_need_videotron',
        'event_equipment_need_webcam',
      ],
    ),
    NeedOption(
      id: 'new_employee',
      label: 'New employee account creation',
      requestCategoryCode: 'new_employee_req',
      fieldKind: NeedFieldKind.newEmployeeForm,
    ),
    NeedOption(
      id: 'others',
      label: 'Others',
      requestCategoryCode: 'other_req',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify',
      textFieldCode: 'other_desc',
    ),
  ];

  static const _media = <NeedOption>[
    NeedOption(
      id: 'design',
      label: 'Design (poster, banner, streamer, logo)',
      requestCategoryCode: 'desain_req',
    ),
    NeedOption(
      id: 'documentation',
      label: 'Documentation (photo/video)',
      requestCategoryCode: 'dokumentasi_req',
    ),
    NeedOption(
      id: 'printing',
      label: 'Printing (ID card, certificate)',
      requestCategoryCode: 'printing_req',
    ),
    NeedOption(
      id: 'social_media',
      label: 'Social media content (Instagram, WhatsApp)',
      requestCategoryCode: 'social_media_req',
    ),
    NeedOption(
      id: 'others',
      label: 'Others',
      requestCategoryCode: 'other_req',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify',
      textFieldCode: 'other_desc',
    ),
  ];

  static List<NeedOption> optionsFor(RequestCategory category) =>
      category == RequestCategory.it ? _it : _media;
}
