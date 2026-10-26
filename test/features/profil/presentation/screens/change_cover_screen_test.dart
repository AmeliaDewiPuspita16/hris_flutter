import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/profil/data/profil_repository.dart';
import 'package:hris_mobile/features/profil/domain/profile_cover.dart';
import 'package:hris_mobile/features/profil/presentation/screens/change_cover_screen.dart';

Map<String, dynamic> _gradient(String key, String label,
        {bool isDefault = false}) =>
    {
      'key': key,
      'label': label,
      'image_url': null,
      'focus_y': null,
      'colors': ['#0D47A1', '#29B6F6'],
      'is_default': isDefault,
    };

void main() {
  late List<http.Request> requests;
  ProfileCover? result;

  Future<void> pumpScreen(WidgetTester tester,
      {http.Response Function(http.Request)? onUpdate}) async {
    requests = [];
    result = null;
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == ApiConfig.profileCover) {
          return http.Response(
            jsonEncode({
              'code': 200,
              'status': 'success',
              'data': {
                'cover': {
                  'preset': 'forest',
                  'image_url': null,
                  'colors': ['#1B5E20', '#43A047'],
                  'position': null,
                  'has_file': false
                },
                'presets': [
                  _gradient('forest', 'Forest', isDefault: true),
                  _gradient('ocean', 'Ocean'),
                ],
              },
            }),
            200,
          );
        }
        return onUpdate?.call(request) ??
            http.Response(
              jsonEncode({
                'code': 200,
                'status': 'success',
                'message': 'Cover updated.',
                'data': {
                  'cover': {
                    'preset': 'ocean',
                    'image_url': null,
                    'colors': ['#0D47A1', '#29B6F6'],
                    'position': null,
                    'has_file': false
                  },
                },
              }),
              200,
            );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ProfileCover>(
                    MaterialPageRoute(
                      builder: (_) => ChangeCoverScreen(
                        user: const AuthUser(
                            id: 1, name: 'Ari Putra', email: 'ari@biie.co.id'),
                        repository: ProfilRepository(apiClient: apiClient),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan preset dan menandai cover yang terpasang',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Forest (default)'), findsOneWidget);
    expect(find.text('Ocean'), findsOneWidget);
    // Satu-satunya centang ada di tile Forest, cover yang sedang terpasang.
    final check = find.byIcon(Icons.check);
    expect(check, findsOneWidget);
    final forestTile = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Forest (default)',
    );
    expect(find.ancestor(of: check, matching: forestTile), findsOneWidget);
  });

  testWidgets(
      'memilih preset lalu menyimpan mengirim preset dan mengembalikan cover baru',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Ocean'));
    await tester.pump();
    await tester.tap(find.text('Next: preview'));
    await tester.pumpAndSettle();
    expect(find.text('How your profile looks'), findsOneWidget);

    await tester.tap(find.text('Finish & save'));
    await tester.pumpAndSettle();

    final update = requests.last;
    expect(update.url.path, ApiConfig.updateProfileCover);
    expect(update.body, contains('name="preset"\r\n\r\nocean'));
    expect(result?.preset, 'ocean');
    expect(find.byType(ChangeCoverScreen), findsNothing);
  });

  testWidgets('pesan galat server tampil dan layar tidak ditutup',
      (tester) async {
    await pumpScreen(
      tester,
      onUpdate: (_) => http.Response(
        jsonEncode({
          'message': 'That design is not available.',
          'errors': {
            'preset': ['That design is not available.'],
          },
        }),
        422,
      ),
    );

    await tester.tap(find.text('Ocean'));
    await tester.pump();
    await tester.tap(find.text('Next: preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish & save'));
    await tester.pumpAndSettle();

    expect(find.text('That design is not available.'), findsOneWidget);
    expect(find.byType(ChangeCoverScreen), findsOneWidget);
    expect(result, isNull);
  });
}
