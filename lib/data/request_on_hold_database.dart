import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_on_hold.dart';

class RequestOnHoldDatabase {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RequestOnHold>> getRequestOnHolds({String? studentId}) async {
    var query = _client.from('request_on_hold').select(
      'id, reason, student_id, request_status, created_at, updated_at, '
      'students!inner(name, class_name), '
      'request_on_hold_detail(invoice_id, qty, invoices!inner(item_name, bill_month, price_per_item))',
    );
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    final response = await query.order('created_at', ascending: false);
    return response
        .map((e) => RequestOnHold.fromMap(e))
        .toList();
  }

  Future<void> submit({
    required String studentId,
    required String reason,
    required List<String> invoiceIds,
  }) async {
    await _client.rpc('submit_hold_request', params: {
      'p_student_id': studentId,
      'p_reason': reason,
      'p_invoice_ids': invoiceIds,
    });
  }

  Future<void> decide(String requestId, {required bool approve}) async {
    await _client.rpc('decide_hold_request', params: {
      'p_request_id': requestId,
      'p_approve': approve,
    });
  }
}