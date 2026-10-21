import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_private.dart' as employee_private;
import 'user_database.dart';

class EmployeePrivateDatabase {
  final supabase = Supabase.instance.client;

  Future<employee_private.EmployeePrivate?> getMyEmployeePrivateData() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final id = authUser.id;

    // Get private data
    final privateResponse = await supabase
        .from('employee_private')
        .select(
          '*, organization:organizations(*), job_position:job_positions(*), job_level:job_levels(*)',
        )
        .eq('auth_id', id)
        .maybeSingle();

    if (privateResponse == null) return null;

    final approvalLineResponse = await UserDatabase().getUserPublicDataByAuthId(
      privateResponse['approval_line_auth_id'],
    );
    final managerResponse = await UserDatabase().getUserPublicDataByAuthId(
      privateResponse['manager_line_auth_id'],
    );

    final employeePrivate = employee_private.EmployeePrivate.fromMap({
      ...privateResponse,
      'approval_line': approvalLineResponse?.toMap(),
      'manager': managerResponse?.toMap(),
    });

    return employeePrivate;
  }
}
