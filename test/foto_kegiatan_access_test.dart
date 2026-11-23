import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekolahbinekas/models/user.dart' as local_user;
import 'package:sekolahbinekas/models/user_cache.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <Uri>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(persistSession: false),
      httpClient: MockClient((request) async {
        requests.add(request.url);
        final result = switch (request.url.path) {
          '/rest/v1/students' => [
            {'id': 'student-1'},
          ],
          '/rest/v1/foto_student_access' => [
            {'foto_kegiatan_id': 'photo-1'},
          ],
          '/rest/v1/foto_kegiatan' => [
            {
              'id': 'photo-1',
              'link_foto': 'https://example.com/album',
              'nama_kegiatan': 'Kegiatan',
              'thumbnail_foto': 'https://example.com/image.jpg',
              'classes_name': ['Kelas'],
              'only_ppi': true,
              'created_at': '2026-01-01T00:00:00Z',
            },
          ],
          _ => throw StateError('Unexpected request: ${request.url}'),
        };
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(requests.clear);
  tearDown(UserCache.clear);

  for (final role in ['bidang_study_tk', 'bidang_study_sd']) {
    testWidgets('$role loads RLS-scoped photos without student filtering', (
      tester,
    ) async {
      UserCache.setUser(
        local_user.User(id: 'user', display_name: 'User', role: role),
      );

      await tester.pumpWidget(const MaterialApp(home: FotoKegiatanScreen()));
      await tester.pumpAndSettle();

      expect(requests.map((uri) => uri.path), ['/rest/v1/foto_kegiatan']);
      expect(requests.single.queryParameters.containsKey('id'), isFalse);
      expect(find.text('Kegiatan'), findsOneWidget);
    });
  }

  testWidgets('other roles continue to filter photos by accessible students', (
    tester,
  ) async {
    UserCache.setUser(
      local_user.User(id: 'user', display_name: 'User', role: 'parent'),
    );

    await tester.pumpWidget(const MaterialApp(home: FotoKegiatanScreen()));
    await tester.pumpAndSettle();

    expect(requests.map((uri) => uri.path), [
      '/rest/v1/students',
      '/rest/v1/foto_student_access',
      '/rest/v1/foto_kegiatan',
    ]);
    expect(requests.last.queryParameters['id'], contains('photo-1'));
    expect(find.text('Kegiatan'), findsOneWidget);
  });
}
