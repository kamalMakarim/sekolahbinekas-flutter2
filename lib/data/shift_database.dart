import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift.dart';

class ShiftDatabase {
  final supabase = Supabase.instance.client;

  Future<Shift?> getShiftById(String id) async {
    final response = await supabase
        .from('shifts')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : Shift.fromMap(response);
  }

  Future<List<Shift>> getRequestableShifts() async {
    final response = await supabase
        .from('shifts')
        .select('*')
        .eq('is_requestable', true);
    return (response as List).map((shift) => Shift.fromMap(shift)).toList();
  }
}
