import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekolahbinekas/data/image_database.dart';

class AbsenLogic {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMonthlyAttendance(
    DateTime currentMonth,
  ) async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return [];

    final startDate = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    ).toIso8601String().split('T')[0];

    final endDate = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).toIso8601String().split('T')[0];

    final response = await _supabase
        .from('employee_attendance')
        .select('attendance_date, check_in, check_out, status')
        .eq('auth_id', authId)
        .gte('attendance_date', startDate)
        .lte('attendance_date', endDate);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('employee_attendance')
        .select('id, check_in, check_in_method, check_out, check_out_method')
        .eq('auth_id', authId)
        .eq('attendance_date', today)
        .maybeSingle();

    return response;
  }

  Future<Map<String, bool?>> getTodaySelfieVerification() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return {};

    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('manual_attendance_details')
        .select('record_type, is_verified, created_at')
        .eq('auth_id', authId)
        .gte('created_at', '${today}T00:00:00')
        .lte('created_at', '${today}T23:59:59')
        .order('created_at', ascending: false);

    final statuses = <String, bool?>{};
    for (final item in response as List) {
      final recordType = item['record_type'] as String;
      statuses.putIfAbsent(recordType, () => item['is_verified'] as bool?);
    }
    return statuses;
  }

  Future<String?> uploadSelfie(File file) async {
    try {
      final url = await ImageDatabase().uploadImages([file]);

      if (url.isNotEmpty) {
        return url.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitSelfieAttendance({
    required String selfieUrl,
    required double locationLat,
    required double locationLng,
    required String recordType,
  }) async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return;

    await _supabase.from('manual_attendance_details').insert({
      'auth_id': authId,
      'selfie_url': selfieUrl,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'record_type': recordType,
    });
  }

  Future<String?> getOrCreateAttendanceId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final existing = await _supabase
        .from('employee_attendance')
        .select('id')
        .eq('auth_id', authId)
        .eq('attendance_date', today)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final inserted = await _supabase
        .from('employee_attendance')
        .insert({'auth_id': authId, 'attendance_date': today})
        .select('id')
        .single();

    return inserted['id'] as String;
  }
}
