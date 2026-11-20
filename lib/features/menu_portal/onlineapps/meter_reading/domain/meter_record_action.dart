/// Aksi yang boleh dilakukan user pada satu record — SUMBER KEBENARAN dari
/// server (`action`), bukan tebakan klien dari status.
///
/// | action        | endpoint                          | tombol          |
/// |---------------|-----------------------------------|-----------------|
/// | `record`      | POST /records/{id}                | Record New Data |
/// | `edit`        | POST /records/{id}                | Edit Record     |
/// | `new_reading` | POST /records/{id}/new_reading    | New Reading     |
/// | null          | —                                 | (sembunyikan)   |
///
/// [none] berarti sudah approved di periode ini, atau tidak ada periode
/// aktif. Kode tak dikenal juga jatuh ke [none]: lebih aman menyembunyikan
/// tombol daripada menembak endpoint yang salah.
enum MeterRecordAction {
  record('record', 'Record New Data'),
  edit('edit', 'Edit Record'),
  newReading('new_reading', 'New Reading'),
  none('', '');

  const MeterRecordAction(this.code, this.buttonLabel);

  final String code;

  /// Teks tombol / judul form. Kosong untuk [none].
  final String buttonLabel;

  static MeterRecordAction fromCode(String? code) => switch (code) {
        'record' => MeterRecordAction.record,
        'edit' => MeterRecordAction.edit,
        'new_reading' => MeterRecordAction.newReading,
        _ => MeterRecordAction.none,
      };

  bool get isAvailable => this != MeterRecordAction.none;
}
