import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentOptionDatabase {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPaymentOptionsByStudentId(
    String studentId,
  ) async {
    final response = await supabase
        .from('payment_option')
        .select('id, payment_method, va_number, key, student_id')
        .eq('student_id', studentId);

    final paymentOptions = response
        .map((data) => Map<String, dynamic>.from(data))
        .toList();

    return paymentOptions;
  }
}
