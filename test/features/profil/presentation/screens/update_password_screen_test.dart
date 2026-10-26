import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/features/profil/data/profil_repository.dart';
import 'package:hris_mobile/features/profil/presentation/screens/update_password_screen.dart';

void main() {
  late List<http.Request> requests;

  Future<void> pumpScreen(
    WidgetTester tester, {
    http.Response Function()? respond,
  }) {
    requests = [];
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return respond?.call() ??
            http.Response(
              jsonEncode({
                'code': 200,
                'status': 'success',
                'message': 'Password changed successfully.',
                'data': null,
              }),
              200,
            );
      }),
    );
    return tester.pumpWidget(
      MaterialApp(
        home: UpdatePasswordScreen(
          repository: ProfilRepository(apiClient: apiClient),
        ),
      ),
    );
  }

  Future<void> fill(WidgetTester tester, String current, String next,
      String confirm) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), next);
    await tester.enterText(fields.at(2), confirm);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pumpAndSettle();
  }

  testWidgets('validasi lokal mencegah request saat isian salah',
      (tester) async {
    await pumpScreen(tester);

    await submit(tester);
    expect(find.text('Current password is required'), findsOneWidget);

    await fill(tester, 'lama12345', 'baru12345', 'beda12345');
    await submit(tester);
    expect(find.text('Passwords do not match'), findsOneWidget);

    await fill(tester, 'lama12345', 'pendek', 'pendek');
    await submit(tester);
    expect(
      find.text('New password must be at least '
          '${UpdatePasswordScreen.minLength} characters'),
      findsOneWidget,
    );

    expect(requests, isEmpty);
  });

  testWidgets('mengirim password lama, baru, dan konfirmasinya',
      (tester) async {
    await pumpScreen(tester);

    await fill(tester, 'lama12345', 'baru12345', 'baru12345');
    await submit(tester);

    expect(requests, hasLength(1));
    expect(requests.single.url.path, ApiConfig.updatePassword);
    expect(jsonDecode(requests.single.body), {
      'current_password': 'lama12345',
      'new_password': 'baru12345',
      'new_password_confirmation': 'baru12345',
    });
  });

  testWidgets('pesan validasi server ditampilkan', (tester) async {
    await pumpScreen(
      tester,
      respond: () => http.Response(
        jsonEncode({
          'message': 'The current password is incorrect.',
          'errors': {
            'current_password': ['The current password is incorrect.'],
          },
        }),
        422,
      ),
    );

    await fill(tester, 'salah1234', 'baru12345', 'baru12345');
    await submit(tester);

    expect(find.text('The current password is incorrect.'), findsOneWidget);
  });
}
