import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_public.dart' as employee_public;

class EmployeePublicDatabase {
  final supabase = Supabase.instance.client;

  Future<employee_public.EmployeePublic?> getMyEmployeePublicData({
    bool forceRefresh = false,
  }) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final id = authUser.id;

    // Get public data
    final publicResponse = await supabase
        .from('employee_public')
        .select('*')
        .eq('auth_id', id)
        .maybeSingle();

     if (publicResponse == null) {
      throw Exception('Error fetching employee public data');
    }

    final employeePublic = employee_public.EmployeePublic.fromMap(publicResponse);

    return employeePublic;
  }

  Future<employee_public.EmployeePublic?> getEmployeePublicDataByAuthId(String authId) async {
    // Get public data
    final publicResponse = await supabase
        .from('employee_public')
        .select('*')
        .eq('auth_id', authId)
        .maybeSingle();

     if (publicResponse == null) {
      throw Exception('Error fetching employee public data');
    }

    final employeePublic = employee_public.EmployeePublic.fromMap(publicResponse);

    return employeePublic;
  }
}