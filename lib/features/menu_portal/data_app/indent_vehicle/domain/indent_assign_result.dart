/// Hasil popup "Assign Vehicle" yang dikembalikan ke layar: plat nomor
/// (wajib) dan nama driver (null kalau request tanpa driver).
class IndentAssignResult {
  const IndentAssignResult({required this.plateNumber, this.driver});

  final String plateNumber;
  final String? driver;
}
