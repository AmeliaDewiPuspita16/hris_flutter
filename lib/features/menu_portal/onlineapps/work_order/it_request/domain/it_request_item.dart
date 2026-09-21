import '../../../../../../core/utils/json_value.dart';
import 'checking.dart';
import 'code_label.dart';
import 'it_request_requester.dart';
import 'it_request_status.dart';
import 'it_request_type.dart';

/// Satu request IT/Media, dari `GET /api/portal/apps/it_request`.
class ItRequestItem {
  const ItRequestItem({
    required this.id,
    required this.type,
    required this.supportType,
    required this.category,
    required this.description,
    required this.approval,
    required this.checking,
    required this.status,
    required this.createdAt,
    this.rating,
    this.imageUrl,
    this.requester,
    this.isMine = true,
    this.canRate = false,
  });

  final int id;
  final ItRequestType type;

  /// Label mentah dari server, ex: "PERMINTAAN". Belum ada padanan
  /// enum-nya karena baru satu nilai yang pernah terlihat di contoh.
  final String supportType;

  final CodeLabel category;
  final String description;
  final CodeLabel approval;
  final Checking checking;
  final ItRequestStatus status;

  /// Null selama user belum menilai.
  final int? rating;

  final String? imageUrl;
  final DateTime createdAt;
  final ItRequestRequester? requester;

  /// True bila request ini diajukan oleh user yang sedang login.
  final bool isMine;

  /// Sumber kebenaran untuk "butuh rating" — menggantikan tebakan lama
  /// `status.code == 'done' && rating == null`. Server yang tahu pasti,
  /// bukan klien yang menebak dari kombinasi status dan rating.
  final bool canRate;

  ItRequestItem copyWith({int? rating, bool? canRate}) => ItRequestItem(
        id: id,
        type: type,
        supportType: supportType,
        category: category,
        description: description,
        approval: approval,
        checking: checking,
        status: status,
        createdAt: createdAt,
        rating: rating ?? this.rating,
        imageUrl: imageUrl,
        requester: requester,
        isMine: isMine,
        canRate: canRate ?? this.canRate,
      );

  /// Melempar [FormatException] bila `id` atau `created_at` tidak terbaca.
  /// Request tanpa id tidak bisa dibuka detailnya, dan tanpa tanggal yang
  /// benar bisa nyasar ke urutan yang salah di daftar "terbaru dulu" —
  /// lebih baik satu baris dilewati daripada ditampilkan menyesatkan.
  factory ItRequestItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons IT Request tidak memuat id');
    }

    final createdAt = dateOrNull(json['created_at']);
    if (createdAt == null) {
      throw const FormatException('created_at tidak bisa diurai');
    }

    final requester = json['requester'];

    return ItRequestItem(
      id: id,
      type: ItRequestType.fromCode('${json['type'] ?? ''}'),
      supportType: '${json['support_type'] ?? ''}',
      category: CodeLabel.fromJson(
        json['category'] is Map<String, dynamic>
            ? json['category'] as Map<String, dynamic>
            : null,
      ),
      description: '${json['description'] ?? ''}',
      approval: CodeLabel.fromJson(
        json['approval'] is Map<String, dynamic>
            ? json['approval'] as Map<String, dynamic>
            : null,
      ),
      checking: Checking.fromJson(
        json['checking'] is Map<String, dynamic>
            ? json['checking'] as Map<String, dynamic>
            : null,
      ),
      status: ItRequestStatus.fromJson(
        json['status'] is Map<String, dynamic>
            ? json['status'] as Map<String, dynamic>
            : null,
      ),
      rating: json['rating'] is int ? json['rating'] as int : null,
      imageUrl: textOrNull(json['image_url']),
      createdAt: createdAt,
      requester: requester is Map<String, dynamic>
          ? ItRequestRequester.fromJson(requester)
          : null,
      // Server belum selalu mengirim kedua field ini (mis. respons lama) —
      // default true/false dipilih supaya kode lama tetap aman: dianggap
      // request sendiri, dan tidak bisa dinilai sampai server bilang bisa.
      isMine: json['is_mine'] is bool ? json['is_mine'] as bool : true,
      canRate: json['can_rate'] == true,
    );
  }
}
