import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sekolahbinekas/models/user.dart' as local_user;
import 'package:sekolahbinekas/models/user_cache.dart';
import 'package:sekolahbinekas/presentation/screens/payment/accountant_hold_request_screen.dart';
import 'package:sekolahbinekas/presentation/screens/payment/parent_hold_request_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <http.Request>[];
  var status = 'pending';
  var showRequest = false;
  var failDecision = false;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(persistSession: false),
      httpClient: MockClient((request) async {
        calls.add(request);
        final invoice = {
          'id': 'invoice-1',
          'student_id': 'student-1',
          'bill_month': '2026-01-01',
          'status': 'issued',
          'item_name': 'SPP',
          'price_per_item': 100000,
          'quantity': 1,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };
        Object? result;
        switch (request.url.path) {
          case '/rest/v1/students':
            result = [
              {
                'id': 'student-1',
                'parent_auth_id': 'parent',
                'name': 'Anak',
                'batch': 2026,
                'class_name': 'Kelas A',
                'ppi': false,
              },
            ];
          case '/rest/v1/invoices':
            result = [invoice];
          case '/rest/v1/request_on_hold':
            result = showRequest
                ? [
                    {
                      'id': 'request-1',
                      'student_id': 'student-1',
                      'reason': 'Alasan',
                      'request_status': status,
                      'created_at': '2026-01-01T00:00:00Z',
                      'updated_at': '2026-01-02T00:00:00Z',
                      'students': {'name': 'Anak', 'class_name': 'Kelas A'},
                      'request_on_hold_detail': [
                        {
                          'invoice_id': 'invoice-1',
                          'qty': 1,
                          'invoices': {
                            'item_name': 'SPP',
                            'bill_month': '2026-01-01',
                            'price_per_item': 100000,
                          },
                        },
                      ],
                    },
                  ]
                : [];
          case '/rest/v1/rpc/submit_hold_request':
            showRequest = true;
            result = 'request-1';
          case '/rest/v1/rpc/decide_hold_request':
            if (failDecision) {
              return http.Response(
                jsonEncode({'message': 'Invoice changed'}),
                400,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            status =
                (jsonDecode(request.body)
                        as Map<String, dynamic>)['p_approve'] ==
                    true
                ? 'approved'
                : 'rejected';
            result = null;
          default:
            throw StateError('Unexpected request: ${request.url}');
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  setUp(() {
    calls.clear();
    status = 'pending';
    showRequest = false;
    failDecision = false;
    UserCache.setUser(
      local_user.User(id: 'parent', display_name: 'Parent', role: 'parent'),
    );
  });
  tearDown(UserCache.clear);

  testWidgets(
    'parent submits selected invoice and pending invoice cannot be selected again',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ParentHoldRequestScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.enterText(find.byType(TextField), 'Alasan');
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Kirim pengajuan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim pengajuan'));
      await tester.pumpAndSettle();

      final request = calls.singleWhere(
        (call) => call.url.path.endsWith('/submit_hold_request'),
      );
      expect(jsonDecode(request.body), {
        'p_student_id': 'student-1',
        'p_reason': 'Alasan',
        'p_invoice_ids': ['invoice-1'],
      });
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(find.text('Menunggu'), findsOneWidget);
    },
  );

  testWidgets('accountant can approve and see the request in history', (
    tester,
  ) async {
    showRequest = true;
    await tester.pumpWidget(
      const MaterialApp(home: AccountantHoldRequestScreen()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Setujui'));
    await tester.tap(find.text('Setujui'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setujui').last);
    await tester.pumpAndSettle();
    expect(status, 'approved');
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Alasan'), findsNWidgets(2));
  });

  testWidgets('failed decision stays pending and displays an error', (
    tester,
  ) async {
    showRequest = true;
    failDecision = true;
    await tester.pumpWidget(
      const MaterialApp(home: AccountantHoldRequestScreen()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tolak'));
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak').last);
    await tester.pumpAndSettle();
    expect(status, 'pending');
    expect(find.textContaining('tidak dapat diproses'), findsOneWidget);
    expect(find.text('Menunggu'), findsWidgets);
  });

  testWidgets('accountant can reject a request', (tester) async {
    showRequest = true;
    await tester.pumpWidget(
      const MaterialApp(home: AccountantHoldRequestScreen()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tolak'));
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak').last);
    await tester.pumpAndSettle();
    expect(status, 'rejected');
    final request = calls.singleWhere(
      (call) => call.url.path.endsWith('/decide_hold_request'),
    );
    expect(jsonDecode(request.body), {
      'p_request_id': 'request-1',
      'p_approve': false,
    });
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Ditolak'), findsOneWidget);
  });
}
