import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import '../models/change_shift_request.dart';

class ChangeShiftRequestDatabase {
  final supabase = Supabase.instance.client;

  // Get message of a specific student
  Future<ChangeShiftRequest> addChangeShiftRequest(
    DateTime attendanceDate,
    String shiftId,
    String reason,
    String fileUrl,
    String? checkIn,
    String? checkOut,
  ) async {
    String authId = await UserDatabase().getCurrentUserId();

    final insertData = {
      'auth_id': authId,
      'attendance_date': attendanceDate.toIso8601String(),
      'shift_id': shiftId,
      'reason': reason,
      'file_url': fileUrl,
      'check_in': checkIn,
      'check_out': checkOut,
    };

    final response = await supabase
        .from('change_shift_requests')
        .insert(insertData)
        .select()
        .single();
    return ChangeShiftRequest.fromMap(response);
  }

  Future<List<ChangeShiftRequest>>
  getChangeShiftRequestsRequiringMyApproval() async {
    String role = await UserDatabase().getUserRole();
    String authId = await UserDatabase().getCurrentUserId();

    final employeePrivateResponse = await supabase
        .from('employee_private')
        .select('auth_id')
        .eq('approval_line_auth_id', authId);
    final employeeAuthIds = (employeePrivateResponse as List)
        .map((employee) => employee['auth_id'] as String)
        .toList();

    final requests = <Map<String, dynamic>>[];

    if (role == 'hr') {
      final hrResponse = await supabase
          .from('change_shift_requests')
          .select('*, shifts!inner(require_hr_approval)')
          .eq('shifts.require_hr_approval', true)
          .isFilter('is_approved_by_hr', null);
      requests.addAll((hrResponse as List).cast<Map<String, dynamic>>());
    }

    if (employeeAuthIds.isNotEmpty) {
      final approvalLineResponse = await supabase
          .from('change_shift_requests')
          .select()
          .inFilter('auth_id', employeeAuthIds)
          .isFilter('is_approved_by_approval_line', null);
      requests.addAll(
        (approvalLineResponse as List).cast<Map<String, dynamic>>(),
      );
    }

    final uniqueRequests = <String, Map<String, dynamic>>{
      for (final request in requests) request['id'] as String: request,
    };

    return uniqueRequests.values.map(ChangeShiftRequest.fromMap).toList();
  }

  Future<List<ChangeShiftRequest>> getMyChangeShiftRequests() async {
    final authId = await UserDatabase().getCurrentUserId();
    final response = await supabase
        .from('change_shift_requests')
        .select()
        .eq('auth_id', authId)
        .order('created_at', ascending: false);
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(ChangeShiftRequest.fromMap)
        .toList();
  }

  Future<bool> approveChangeShiftRequest(String id, bool isApproved) async {
    String role = await UserDatabase().getUserRole();
    String authId = await UserDatabase().getCurrentUserId();

    final request = await supabase
        .from('change_shift_requests')
        .select('auth_id')
        .eq('id', id)
        .single();

    final isApprovalLine = await supabase
        .from('employee_private')
        .select('auth_id')
        .eq('approval_line_auth_id', authId)
        .eq('auth_id', request['auth_id'])
        .maybeSingle();

    final updateData = <String, dynamic>{};

    if (role == 'hr') {
      updateData['is_approved_by_hr'] = isApproved;
    }

    if (isApprovalLine != null) {
      updateData['is_approved_by_approval_line'] = isApproved;
    }

    if (updateData.isEmpty) return false;

    await supabase
        .from('change_shift_requests')
        .update(updateData)
        .eq('id', id);
    return true;
  }

  Future<bool> updateChangeShiftRequestTimes(
    String id,
    String? checkIn,
    String? checkOut,
  ) async {
    final role = await UserDatabase().getUserRole();
    final authId = await UserDatabase().getCurrentUserId();

    final request = await supabase
        .from('change_shift_requests')
        .select('auth_id')
        .eq('id', id)
        .single();

    final isApprovalLine = await supabase
        .from('employee_private')
        .select('auth_id')
        .eq('approval_line_auth_id', authId)
        .eq('auth_id', request['auth_id'])
        .maybeSingle();

    if (role != 'hr' && isApprovalLine == null) return false;

    await supabase
        .from('change_shift_requests')
        .update({'check_in': checkIn, 'check_out': checkOut})
        .eq('id', id);
    return true;
  }

  Future<bool> updateChangeShiftRequestDate(
    String id,
    DateTime attendanceDate,
  ) async {
    final role = await UserDatabase().getUserRole();
    final authId = await UserDatabase().getCurrentUserId();

    final request = await supabase
        .from('change_shift_requests')
        .select('auth_id')
        .eq('id', id)
        .single();

    final isApprovalLine = await supabase
        .from('employee_private')
        .select('auth_id')
        .eq('approval_line_auth_id', authId)
        .eq('auth_id', request['auth_id'])
        .maybeSingle();

    if (role != 'hr' && isApprovalLine == null) return false;

    await supabase
        .from('change_shift_requests')
        .update({'attendance_date': attendanceDate.toIso8601String()})
        .eq('id', id);
    return true;
  }
}
