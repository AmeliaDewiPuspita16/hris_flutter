import 'package:file_picker/file_picker.dart';

/// Berkas yang dipilih user untuk diunggah (dokumen permit / evidence).
typedef HsePickedFile = ({String path, String name, int sizeBytes});

/// Membuka pemilih berkas dengan [extensions] yang diizinkan. Null bila
/// dibatalkan atau path tidak tersedia.
Future<HsePickedFile?> pickHseFile(List<String> extensions) async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  final path = file?.path;
  if (file == null || path == null) return null;
  return (path: path, name: file.name, sizeBytes: await file.length() ?? 0);
}

/// Pesan galat bila [file] lebih besar dari [maxKb], selain itu null.
String? hseFileSizeError(HsePickedFile file, int maxKb) {
  if (file.sizeBytes <= maxKb * 1024) return null;
  final maxMb = (maxKb / 1024).toStringAsFixed(maxKb % 1024 == 0 ? 0 : 1);
  return '${file.name} exceeds the $maxMb MB limit.';
}
