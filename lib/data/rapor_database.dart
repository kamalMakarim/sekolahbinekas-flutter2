import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rapor.dart';

class RaporDatabase {
  final supabase = Supabase.instance.client;

  Future<List<Rapor>> getRaporByStudentId(String studentId) async {
    final response = await supabase
        .from('rapor')
        .select('id, created_at, student_id, semester, tahun_ajaran, status, pdf')
        .eq('student_id', studentId)
        .order('tahun_ajaran', ascending: false)
        .order('semester', ascending: false);

    // response is expected to be a List<dynamic>
    final rapors = (response as List)
        .map((data) => Rapor.fromMap(data))
        .toList();
    return rapors;
  }
}