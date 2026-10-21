import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_database.dart';
import '../models/unread_count.dart';

class UnreadCountDatabase {
  final supabase = Supabase.instance.client;

  Future<List<UnreadCount>> getAllofUser() async {
    final userId = await UserDatabase().getCurrentUserId();
    final response = await supabase
        .from('unread_count')
        .select()
        .eq('auth_id', userId);
    return (response as List).map((u) => UnreadCount.fromMap(u)).toList();
  }

  Future<bool> setCountToZeroByStudent(String studentId)async {
    final userId = await UserDatabase().getCurrentUserId();
    final response = await supabase
      .from('unread_count')
      .update({'count': 0})
      .eq('auth_id', userId)
      .eq('student_id', studentId);
    return response != null;
  }
}