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

/// Daftar BAWAAN opsi "What do you need?" untuk tiap [RequestCategory].
///
/// Sumber utamanya sekarang `GET /api/portal/apps/it_request/options` (lihat
/// `ItRequestFormOptions`); daftar ini hanya dipakai kalau permintaan itu
/// belum selesai atau gagal, jadi isinya dijaga sama dengan yang terakhir
/// dikirim server (30 Okt 2026: Backup dan Internet dihapus; hardware dan
/// event equipment ditambah).
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
      id: 'download_install',
      label: 'Download/install application',
      requestCategoryCode: 'download_req',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify application name',
      textFieldCode: 'download_desc',
    ),
    NeedOption(
      id: 'hardware',
      label: 'Computer/IT hardware',
      requestCategoryCode: 'perangkat_komputer_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'Laptop',
        'PC',
        'Printer',
        'Mouse',
        'Keyboard',
        'Mousepad',
        'Monitor',
        'TV',
      ],
      checkboxFieldCodes: [
        'hardware_need_laptop',
        'hardware_need_pc',
        'hardware_need_printer',
        'hardware_need_mouse',
        'hardware_need_keyboard',
        'hardware_need_mousepad',
        'hardware_need_monitor',
        'hardware_need_tv',
      ],
    ),
    NeedOption(
      id: 'event_setup',
      label: 'Setup Event/Meeting Equipment',
      requestCategoryCode: 'event_equipment_req',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'Projector',
        'Pointer',
        'Videotron',
        'Webcam',
        'USB Hub',
        'Monitor',
        'TV',
      ],
      checkboxFieldCodes: [
        'event_equipment_need_projector',
        'event_equipment_need_pointer',
        'event_equipment_need_videotron',
        'event_equipment_need_webcam',
        'event_equipment_need_usb_hub',
        'event_equipment_need_monitor',
        'event_equipment_need_tv',
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
      label: 'Design',
      requestCategoryCode: 'desain_req',
    ),
    NeedOption(
      id: 'documentation',
      label: 'Documentation',
      requestCategoryCode: 'dokumentasi_req',
    ),
    NeedOption(
      id: 'printing',
      label: 'Printing',
      requestCategoryCode: 'printing_req',
    ),
    NeedOption(
      id: 'social_media',
      label: 'Social media content',
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
