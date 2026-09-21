import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';

/// Repository sungguhan di atas HTTP tiruan — sama alasannya dengan
/// `ProcurementHarness`: dengan begini pemetaan JSON dan penyusunan query
/// ikut teruji saat menguji bloc, bukan cuma alur state-nya.
class ItRequestHarness {
  ItRequestHarness(this._respond);

  final Future<http.Response> Function(Uri url, int callCount) _respond;

  final List<Uri> requested = [];

  late final ItRequestRepository repository = ItRequestRepository(
    apiClient: ApiClient(
      httpClient: MockClient((request) {
        requested.add(request.url);
        return _respond(request.url, requested.length);
      }),
    ),
  );

  Uri get lastRequest => requested.last;
}

Future<http.Response> ok(Map<String, dynamic> body) async =>
    http.Response(jsonEncode(body), 200);

Future<http.Response> fails({int statusCode = 500, String message = 'Server sibuk'}) async =>
    http.Response(jsonEncode({'message': message}), statusCode);
