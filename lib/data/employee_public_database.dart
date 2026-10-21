import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_public.dart';

class EmployeePublicDatabase {
  final supabase = Supabase.instance.client;

  Future<EmployeePublic?> getMyEmployeePublicData() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final response = await supabase
        .from('employee_public')
        .select('*')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    return response == null ? null : EmployeePublic.fromMap(response);
  }
}
