import '../../../../../../core/utils/json_value.dart';

/// Pengaju request, dari `requester` di respons detail.
class ItRequestRequester {
  const ItRequestRequester({required this.id, required this.name, required this.department});

  final int id;
  final String name;
  final String department;

  factory ItRequestRequester.fromJson(Map<String, dynamic> json) {
    return ItRequestRequester(
      id: intOr(json['id'], 0),
      name: '${json['name'] ?? ''}',
      department: '${json['department'] ?? ''}',
    );
  }
}
