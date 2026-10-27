import '../../../core/network/api_config.dart';
import '../../profil/domain/profile_cover.dart';

/// Pengguna yang sedang masuk, hasil pemetaan `data.user` dari API login.
///
/// Hanya [id], [name], dan [email] yang diwajibkan. Sisanya nullable dengan
/// sengaja: satu field kosong pada satu akun tidak boleh menggagalkan login.
///
/// `fcm_token`, `last_login_ip`, dan timestamp dari server tidak disimpan
/// karena tidak ada yang memakainya di aplikasi ini.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.nik,
    this.phone,
    this.section,
    this.departmentId,
    this.subDepartmentId,
    this.dateOfBirth,
    this.gender,
    this.image,
    this.avatar,
    this.roles = const [],
    this.cover,
  });

  final int id;
  final String name;
  final String email;
  final String? nik;
  final String? phone;
  final String? section;
  final int? departmentId;
  final int? subDepartmentId;
  final String? dateOfBirth;
  final String? gender;

  /// Nama berkas foto dari server, misalnya `ElAfRc….jpg` — BUKAN URL penuh.
  /// Prefix direktorinya belum diketahui, jadi disimpan apa adanya.
  final String? image;

  final String? avatar;

  /// Nama role saja, misalnya `['gmo', 'it media']`. Objek role dari server
  /// (`guard_name`, `pivot`, timestamp) dibuang karena tidak dipakai.
  final List<String> roles;

  /// Cover kartu profil (objek `cover` di respons login). Null kalau server
  /// belum mengirimnya — header Profil memakai gambar bawaan.
  final ProfileCover? cover;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']) ?? '',
      email: _asString(json['email']) ?? '',
      nik: _asString(json['nik']),
      phone: _asString(json['no_hp']),
      section: _asString(json['section']),
      departmentId: _asInt(json['id_department']),
      subDepartmentId: _asInt(json['id_sub_department']),
      dateOfBirth: _asString(json['date_of_birth']),
      gender: _asString(json['gender']),
      image: _asString(json['image']),
      avatar: _asString(json['avatar']),
      roles: _rolesFrom(json['roles']),
      cover: ProfileCover.fromJson(json['cover']),
    );
  }

  /// Kebalikan dari [fromJson], memakai nama field yang sama dengan server
  /// supaya hasilnya bisa dibaca ulang oleh [fromJson].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nik': nik,
      'no_hp': phone,
      'section': section,
      'id_department': departmentId,
      'id_sub_department': subDepartmentId,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'image': image,
      'avatar': avatar,
      'roles': [
        for (final role in roles) {'name': role},
      ],
      'cover': cover?.toJson(),
    };
  }

  /// Salinan dengan [cover] baru, mis. setelah user mengganti cover.
  AuthUser copyWithCover(ProfileCover? cover) => AuthUser(
        id: id,
        name: name,
        email: email,
        nik: nik,
        phone: phone,
        section: section,
        departmentId: departmentId,
        subDepartmentId: subDepartmentId,
        dateOfBirth: dateOfBirth,
        gender: gender,
        image: image,
        avatar: avatar,
        roles: roles,
        cover: cover,
      );

  /// Nama panggilan untuk sapaan di Beranda.
  String get firstName => _nameParts.isEmpty ? '' : _nameParts.first;

  /// Inisial untuk avatar bulat: huruf depan nama pertama dan terakhir.
  String get initials {
    final parts = _nameParts;
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Nama dipecah per kata, tahan terhadap spasi berlebih dari server.
  List<String> get _nameParts =>
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  /// URL foto profil yang siap dimuat, dibangun dari [image] (nama berkas
  /// apa adanya dari server) — null kalau user belum punya foto.
  ///
  /// Beda dari lampiran pengumuman/PR yang server-nya sudah mengirim URL
  /// penuh: di sini prefix foldernya (`storage/profile/`) belum pernah
  /// dikirim server, jadi klien yang menyusunnya sendiri.
  String? get photoUrl =>
      image == null || image!.isEmpty ? null : '${ApiConfig.baseUrl}/storage/profile/$image';

  /// Boleh menerbitkan pengumuman HR — izin `hr-announcement-post`, yang
  /// menurut dokumentasi API dimiliki role `hrga` dan `admin`.
  ///
  /// Pemeriksaan di sini hanya untuk menyembunyikan tombol; server tetap
  /// penentu terakhir dan akan membalas 403 bila tidak berhak.
  bool get canPublishAnnouncement =>
      hasRole('hrga') || hasRole('admin');

  /// Boleh mengakses tab tim IT (List Request/Report) di IT Request —
  /// dimiliki role `it media` dan `admin`.
  ///
  /// Sama seperti [canPublishAnnouncement]: cuma untuk menyembunyikan tab,
  /// server tetap penentu terakhir.
  bool get canManageItRequest =>
      hasRole('it media') || hasRole('admin');

  /// Admin driver (`driver-admin`) dan admin umum (`admin`) — berhak melihat
  /// tab Pending Vehicle Assignment di Indent Vehicle (menetapkan plat &
  /// driver).
  ///
  /// Hanya untuk menyembunyikan tab; server tetap penentu terakhir (akun
  /// yang tidak berhak dibalas `admin: false`, jadi tab-nya kosong).
  bool get canAssignIndentVehicle =>
      hasRole('driver-admin') || hasRole('admin');

  /// Driver kendaraan (role `driver`) — di Indent Vehicle hanya melihat
  /// perjalanan yang ditugaskan kepadanya (tab My Assignments).
  ///
  /// Server yang menyaring isinya per driver; pemeriksaan di sini hanya
  /// untuk menentukan tab apa yang tampil.
  bool get isDriver => hasRole('driver');

  /// Atasan (role `hod`) — berhak melihat shortcut approval di Beranda.
  ///
  /// Sama seperti getter lain di sini: hanya untuk menampilkan/menyembunyikan
  /// UI, server tetap penentu terakhir.
  bool get isHod => hasRole('hod');

  bool hasRole(String role) {
    final target = role.toLowerCase();
    return roles.any((r) => r.toLowerCase() == target);
  }

  static List<String> _rolesFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((role) => _asString(role['name']))
        .whereType<String>()
        .toList(growable: false);
  }

  /// Server kadang mengirim angka sebagai teks; keduanya diterima.
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _asString(dynamic value) {
    if (value is String) return value;
    return value?.toString();
  }
}
