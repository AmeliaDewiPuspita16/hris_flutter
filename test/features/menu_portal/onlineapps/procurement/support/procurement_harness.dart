import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/data/procurement_repository.dart';

/// Repository sungguhan di atas HTTP tiruan.
///
/// Sengaja bukan ProcurementRepository palsu: dengan begini pemetaan JSON
/// dan penyusunan query ikut teruji saat menguji bloc, bukan cuma alur
/// state-nya.
class ProcurementHarness {
  ProcurementHarness(this._respond);

  /// Dipanggil tiap request; [requested] menyimpan URL yang sudah diminta
  /// supaya test bisa memeriksa query yang dikirim bloc.
  final Future<http.Response> Function(Uri url, int callCount) _respond;

  final List<Uri> requested = [];

  late final ProcurementRepository repository = ProcurementRepository(
    apiClient: ApiClient(
      httpClient: MockClient((request) {
        requested.add(request.url);
        return _respond(request.url, requested.length);
      }),
    ),
  );

  Uri get lastRequest => requested.last;
}

/// Balasan 200 berisi [body].
Future<http.Response> ok(Map<String, dynamic> body) async =>
    http.Response(jsonEncode(body), 200);

/// Balasan gagal dengan pesan dari server.
Future<http.Response> fails({
  int statusCode = 500,
  String message = 'Server sibuk',
}) async =>
    http.Response(jsonEncode({'message': message}), statusCode);
