import 'package:sekolahbinekas/data/user_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentOptionDatabase {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPaymentOptionsByStudentId(String studentId) async {
    final response = await supabase
        .from('payment_options')
        .select('id, payment_method, va_number, key, student_id')
        .eq('student_id', studentId);

    // response is expected to be a List<dynamic>
    final paymentOptions = (response as List)
        .map((data) => data as Map<String, dynamic>)
        .toList();
    return paymentOptions;
  }
}