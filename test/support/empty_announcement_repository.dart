import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/home/data/announcement_repository.dart';

/// Repository pengumuman yang selalu membalas daftar kosong.
///
/// Dipakai test yang merender BerandaScreen tapi tidak sedang menguji
/// pengumuman — layar itu memuat daftarnya sendiri saat tampil, jadi
/// providernya tetap harus ada.
AnnouncementRepository emptyAnnouncementRepository() {
  return AnnouncementRepository(
    apiClient: ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': <dynamic>[],
            'meta': {
              'current_page': 1,
              'last_page': 1,
              'per_page': 20,
              'total': 0,
            },
          }),
          200,
        ),
      ),
    ),
  );
}
