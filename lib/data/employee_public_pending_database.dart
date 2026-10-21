import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_public_pending.dart' as employee_public_pending;

class EmployeePublicPendingDatabase {
  final supabase = Supabase.instance.client;

  Future<employee_public_pending.EmployeePublicPending?>
  getMyEmployeePublicPendingData({bool forceRefresh = false}) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final id = authUser.id;

    // Get public data
    final publicResponse = await supabase
        .from('employee_public_pending')
        .select('*')
        .eq('auth_id', id)
        .maybeSingle();

    if (publicResponse == null) return null;

    final employeePublicPending =
        employee_public_pending.EmployeePublicPending.fromMap(publicResponse);

    return employeePublicPending;
  }

  Future<bool> upsertEmployeePublicPendingData(
    employee_public_pending.EmployeePublicPending employeePublicPending,
  ) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return false;

    final id = authUser.id;
    final data = employeePublicPending.toMap()..['auth_id'] = id;

    try {
      final existingRecord = await supabase
          .from('employee_public_pending')
          .select('id')
          .eq('auth_id', id)
          .maybeSingle();

      if (existingRecord != null) {
        await supabase
            .from('employee_public_pending')
            .update(data)
            .eq('auth_id', id);
      } else {
        await supabase.from('employee_public_pending').insert(data);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
