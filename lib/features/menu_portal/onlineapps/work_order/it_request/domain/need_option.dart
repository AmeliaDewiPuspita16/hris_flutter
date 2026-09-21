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
    this.fieldKind = NeedFieldKind.none,
    this.checkboxLabels = const [],
    this.textHint,
  });

  /// ID stabil dipakai sebagai key penyimpanan state (checkbox terpilih,
  /// isi text field) di layar form — bukan untuk ditampilkan.
  final String id;
  final String label;
  final NeedFieldKind fieldKind;

  /// Dipakai kalau [fieldKind] == [NeedFieldKind.checkboxGroup].
  final List<String> checkboxLabels;

  /// Dipakai kalau [fieldKind] == [NeedFieldKind.textField].
  final String? textHint;
}

/// Daftar opsi "What do you need?" untuk tiap [RequestCategory] — mengikuti
/// opsi pada form "Add Request" di versi web apa adanya.
class NeedOptionCatalog {
  NeedOptionCatalog._();

  static const _it = <NeedOption>[
    NeedOption(
      id: 'account_creation',
      label: 'Account creation',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'Email',
        'BIIE Portal account',
        'Synology Drive account',
        'Tenant Feedback account',
      ],
    ),
    NeedOption(
      id: 'account_mgmt',
      label: 'Account management changes',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: [
        'New username',
        'Password reset',
        'Access Permission/Role Change',
        'Deactivate account',
      ],
    ),
    NeedOption(id: 'internet_access', label: 'Internet / network access'),
    NeedOption(id: 'backup_data', label: 'Backup data (weekly)'),
    NeedOption(
      id: 'download_install',
      label: 'Download/install application',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify application name',
    ),
    NeedOption(
      id: 'hardware',
      label: 'Computer/IT hardware (laptop, PC, printer, mouse)',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: ['Laptop', 'PC', 'Printer', 'Mouse'],
    ),
    NeedOption(
      id: 'event_setup',
      label: 'Setup Event/Meeting Equipment',
      fieldKind: NeedFieldKind.checkboxGroup,
      checkboxLabels: ['Projector', 'Pointer', 'Videotron', 'Webcam'],
    ),
    NeedOption(
      id: 'new_employee',
      label: 'New employee account creation',
      fieldKind: NeedFieldKind.newEmployeeForm,
    ),
    NeedOption(
      id: 'others',
      label: 'Others',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify',
    ),
  ];

  static const _media = <NeedOption>[
    NeedOption(id: 'design', label: 'Design (poster, banner, streamer, logo)'),
    NeedOption(id: 'documentation', label: 'Documentation (photo/video)'),
    NeedOption(id: 'printing', label: 'Printing (ID card, certificate)'),
    NeedOption(
      id: 'social_media',
      label: 'Social media content (Instagram, WhatsApp)',
    ),
    NeedOption(
      id: 'others',
      label: 'Others',
      fieldKind: NeedFieldKind.textField,
      textHint: 'Specify',
    ),
  ];

  static List<NeedOption> optionsFor(RequestCategory category) =>
      category == RequestCategory.it ? _it : _media;
}
