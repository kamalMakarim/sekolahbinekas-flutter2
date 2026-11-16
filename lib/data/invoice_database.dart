import 'package:sekolahbinekas/data/user_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invoice.dart';

class InvoiceDatabase {
  final supabase = Supabase.instance.client;

  Future<List<Invoice>> getInvoicesByStudentId(
    String studentId,
    String? billMonth,
    List<String>? statusList
  ) async {
    var query = supabase
        .from('invoices')
        .select(
          'id, student_id, bill_month, status, item_name, price_per_item, quantity, created_at, updated_at',
        )
        .eq('student_id', studentId);

    if (billMonth != null) {
      query = query.eq('bill_month', billMonth);
    }

    if (statusList != null) {
      query = query.inFilter('status', statusList);
    }

    final response = await query;

    // response is expected to be a List<dynamic>
    final invoices = (response as List)
        .map((data) => Invoice.fromMap(data))
        .toList();
    return invoices;
  }
}
