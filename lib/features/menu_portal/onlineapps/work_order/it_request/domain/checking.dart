/// Penanda apakah tim IT sudah meninjau (checking) sebuah request, dari
/// field `checking` di respons.
class Checking {
  const Checking({required this.checked, required this.label});

  final bool checked;
  final String label;

  factory Checking.fromJson(Map<String, dynamic>? json) {
    return Checking(
      checked: json?['checked'] == true,
      label: '${json?['label'] ?? ''}',
    );
  }
}
