import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';
import 'package:hris_mobile/features/profil/data/profil_repository.dart';
import 'package:hris_mobile/features/profil/domain/profile_cover.dart';

import '../../../fixtures/login_response.dart';

/// Contoh `data` dari `GET /api/profile_cover` sesuai dokumentasi API.
Map<String, dynamic> coverData() => {
      'cover': {
        'preset': 'seafront',
        'image_url': 'https://biieportal.co.id/assets/img/bg_login_new.png',
        'colors': [],
        'position': null,
        'has_file': false,
      },
      'presets': [
        {
          'key': 'seafront',
          'label': 'Seafront',
          'image_url': 'https://biieportal.co.id/assets/img/bg_login_new.png',
          'focus_y': 50,
          'colors': [],
          'is_default': true,
        },
        {
          'key': 'forest',
          'label': 'Forest',
          'image_url': null,
          'focus_y': null,
          'colors': ['#1B5E20', '#43A047', '#A5D6A7'],
          'is_default': false,
        },
      ],
    };

Map<String, dynamic> uploadedCover() => {
      'preset': null,
      'image_url': 'https://biieportal.co.id/storage/profile/covers/y6ukJ0.jpg',
      'colors': [],
      'position': {'size': 150, 'x': 20, 'y': 40},
      'has_file': true,
    };

void main() {
  group('ProfileCover', () {
    test('membaca cover gambar upload beserta posisinya', () {
      final cover = ProfileCover.fromJson(uploadedCover())!;

      expect(cover.preset, isNull);
      expect(cover.isImage, isTrue);
      expect(cover.hasFile, isTrue);
      expect(cover.position, const CoverPosition(size: 150, x: 20, y: 40));
    });

    test('preset gradasi: warna hex jadi Color, tanpa gambar', () {
      final forest = CoverPreset.fromJson(coverData()['presets'][1])!;

      expect(forest.isImage, isFalse);
      expect(forest.colors,
          const [Color(0xFF1B5E20), Color(0xFF43A047), Color(0xFFA5D6A7)]);
    });

    test('focus_y preset gambar dipakai sebagai posisi vertikal', () {
      final seafront = CoverPreset.fromJson(coverData()['presets'][0])!;

      expect(seafront.isDefault, isTrue);
      expect(seafront.toCover().position?.y, 50);
    });

    test('toJson bisa dibaca ulang tanpa berubah', () {
      final cover = ProfileCover.fromJson(uploadedCover())!;
      expect(ProfileCover.fromJson(cover.toJson()), cover);

      final forest = CoverPreset.fromJson(coverData()['presets'][1])!.toCover();
      expect(ProfileCover.fromJson(forest.toJson()), forest);
    });
  });

  group('cover di respons login', () {
    test('dibaca dari data.user.cover', () {
      final data = loginResponseData();
      (data['user'] as Map<String, dynamic>)['cover'] = uploadedCover();

      final session = AuthSession.fromJson(data);

      expect(session.user.cover?.hasFile, isTrue);
      // Ikut tersimpan bersama sesi.
      expect(AuthSession.fromJson(session.toJson()).user.cover,
          session.user.cover);
    });

    test('dibaca dari data.cover kalau tidak ada di user', () {
      final data = loginResponseData()..['cover'] = uploadedCover();

      expect(AuthSession.fromJson(data).user.cover?.position?.size, 150);
    });

    test('tanpa cover tetap login, cover null', () {
      expect(AuthSession.fromJson(loginResponseData()).user.cover, isNull);
    });
  });

  group('ProfilRepository cover', () {
    late List<http.Request> requests;

    ProfilRepository repo(Map<String, dynamic> data) {
      requests = [];
      return ProfilRepository(
        apiClient: ApiClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'code': 200,
                'status': 'success',
                'message': 'ok',
                'data': data
              }),
              200,
            );
          }),
        ),
      );
    }

    test('fetchCover mengembalikan cover dan daftar preset', () async {
      final result = await repo(coverData()).fetchCover();

      expect(requests.single.url.path, ApiConfig.profileCover);
      expect(result.cover?.preset, 'seafront');
      expect(result.presets.map((p) => p.key), ['seafront', 'forest']);
    });

    test('memilih preset mengirim field preset', () async {
      await repo({'cover': uploadedCover()}).selectCoverPreset('ocean');

      expect(requests.single.url.path, ApiConfig.updateProfileCover);
      expect(requests.single.body, contains('name="preset"\r\n\r\nocean'));
    });

    test('atur ulang posisi mengirim keep=1 dan position[...]', () async {
      final cover = await repo({'cover': uploadedCover()})
          .repositionCover(const CoverPosition(size: 150, x: 20, y: 40));

      final body = requests.single.body;
      expect(body, contains('name="keep"\r\n\r\n1'));
      expect(body, contains('name="position[size]"\r\n\r\n150'));
      expect(body, contains('name="position[x]"\r\n\r\n20'));
      expect(body, contains('name="position[y]"\r\n\r\n40'));
      expect(cover.position?.size, 150);
    });
  });
}
