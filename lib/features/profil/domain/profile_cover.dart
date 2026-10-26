import 'package:flutter/painting.dart';

/// Posisi gambar cover hasil geser/zoom user, sama dengan field
/// `position[size|x|y]` di API.
class CoverPosition {
  const CoverPosition({this.size = 100, this.x = 50, this.y = 50});

  static const defaultPosition = CoverPosition();

  /// 100–1000: besar gambar dalam % (100 = pas menutupi kartu).
  final int size;

  /// 0–100: titik geser horizontal/vertikal dalam %, seperti
  /// `background-position` CSS (0 = kiri/atas, 100 = kanan/bawah).
  final int x;
  final int y;

  static CoverPosition? fromJson(dynamic json) {
    if (json is! Map) return null;
    return CoverPosition(
      size: (_asInt(json['size']) ?? 100).clamp(100, 1000),
      x: (_asInt(json['x']) ?? 50).clamp(0, 100),
      y: (_asInt(json['y']) ?? 50).clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {'size': size, 'x': x, 'y': y};

  /// Field multipart untuk `POST /api/update_profile_cover`.
  Map<String, String> toFields() => {
        'position[size]': '$size',
        'position[x]': '$x',
        'position[y]': '$y',
      };

  /// Titik geser sebagai [Alignment] Flutter (-1..1).
  Alignment get alignment => Alignment(x / 50 - 1, y / 50 - 1);

  CoverPosition copyWith({int? size, int? x, int? y}) => CoverPosition(
        size: size ?? this.size,
        x: x ?? this.x,
        y: y ?? this.y,
      );

  @override
  bool operator ==(Object other) =>
      other is CoverPosition &&
      other.size == size &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(size, x, y);
}

/// Cover kartu profil milik user — objek `cover` dari
/// `GET /api/profile_cover`, `POST /api/update_profile_cover`, dan respons
/// login.
///
/// Isinya salah satu: gambar ([imageUrl], preset maupun upload sendiri)
/// atau gradasi ([colors], preset seperti `forest`).
class ProfileCover {
  const ProfileCover({
    this.preset,
    this.imageUrl,
    this.colors = const [],
    this.position,
    this.hasFile = false,
  });

  /// Key preset (mis. `seafront`), null kalau cover hasil upload sendiri.
  final String? preset;
  final String? imageUrl;

  /// Warna gradasi untuk preset non-gambar; kosong kalau cover-nya gambar.
  final List<Color> colors;

  /// Posisi gambar upload; null untuk preset.
  final CoverPosition? position;

  /// True kalau user punya gambar upload sendiri di server (bisa diatur
  /// ulang posisinya lewat `keep=1`).
  final bool hasFile;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  static ProfileCover? fromJson(dynamic json) {
    if (json is! Map) return null;
    final rawColors = json['colors'];
    return ProfileCover(
      preset: _asNonEmptyString(json['preset']),
      imageUrl: _asNonEmptyString(json['image_url']),
      colors: rawColors is List ? _parseColors(rawColors) : const [],
      position: CoverPosition.fromJson(json['position']),
      hasFile: json['has_file'] == true || json['has_file'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset,
        'image_url': imageUrl,
        'colors': [for (final c in colors) _hex(c)],
        'position': position?.toJson(),
        'has_file': hasFile,
      };

  @override
  bool operator ==(Object other) =>
      other is ProfileCover &&
      other.preset == preset &&
      other.imageUrl == imageUrl &&
      other.position == position &&
      other.hasFile == hasFile &&
      _sameColors(other.colors, colors);

  @override
  int get hashCode =>
      Object.hash(preset, imageUrl, position, hasFile, Object.hashAll(colors));
}

/// Satu pilihan desain di layar "Change cover".
class CoverPreset {
  const CoverPreset({
    required this.key,
    required this.label,
    this.imageUrl,
    this.focusY,
    this.colors = const [],
    this.isDefault = false,
  });

  final String key;
  final String label;
  final String? imageUrl;

  /// 0–100: bagian vertikal gambar yang ditampilkan, null untuk gradasi.
  final int? focusY;
  final List<Color> colors;
  final bool isDefault;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  static CoverPreset? fromJson(dynamic json) {
    if (json is! Map) return null;
    final key = _asNonEmptyString(json['key']);
    if (key == null) return null;
    final rawColors = json['colors'];
    return CoverPreset(
      key: key,
      label: _asNonEmptyString(json['label']) ?? key,
      imageUrl: _asNonEmptyString(json['image_url']),
      focusY: _asInt(json['focus_y']),
      colors: rawColors is List ? _parseColors(rawColors) : const [],
      isDefault: json['is_default'] == true,
    );
  }

  /// Cover yang akan terpasang kalau preset ini dipilih — untuk preview.
  ProfileCover toCover() => ProfileCover(
        preset: key,
        imageUrl: imageUrl,
        colors: colors,
        position:
            focusY == null ? null : CoverPosition(y: focusY!.clamp(0, 100)),
      );
}

/// Isi `data` dari `GET /api/profile_cover`.
class ProfileCoverData {
  const ProfileCoverData({required this.cover, required this.presets});

  final ProfileCover? cover;
  final List<CoverPreset> presets;
}

/// `#RRGGBB` (atau `#AARRGGBB`) → [Color]; nilai yang tidak valid dilewati.
List<Color> _parseColors(List<dynamic> raw) {
  final result = <Color>[];
  for (final value in raw) {
    if (value is! String) continue;
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = hex.length == 8 ? int.tryParse(hex, radix: 16) : null;
    if (parsed != null) result.add(Color(parsed));
  }
  return result;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

bool _sameColors(List<Color> a, List<Color> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].toARGB32() != b[i].toARGB32()) return false;
  }
  return true;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }
  return null;
}

String? _asNonEmptyString(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}
