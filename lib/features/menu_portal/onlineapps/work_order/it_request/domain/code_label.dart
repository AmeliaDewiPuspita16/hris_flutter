/// Pasangan `{code, label}` generik yang berulang di respons IT Request —
/// `category`, `approval`, dan tiap entri `needs`. Warna/semantik tambahan
/// (kalau perlu) ditambahkan di pemakainya, bukan di sini.
class CodeLabel {
  const CodeLabel({required this.code, required this.label});

  final String code;
  final String label;

  factory CodeLabel.fromJson(Map<String, dynamic>? json) {
    return CodeLabel(
      code: '${json?['code'] ?? ''}',
      label: '${json?['label'] ?? ''}',
    );
  }
}
