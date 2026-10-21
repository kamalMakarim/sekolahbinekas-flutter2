import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import '../models/log.dart';
import '../models/user.dart' as user_model;

class LogDatabase {
  final supabase = Supabase.instance.client;

  // Get message of a specific student
  Future<Log> addLog(
    String message,
    List<String>? imageUrls,
    List<String>? fileUrls,
    String className,
  ) async {
    user_model.User? user = await UserDatabase().getCurrentUserData();

    final insertData = {
      'message': message,
      'user_id': supabase.auth.currentUser?.id,
      'images': imageUrls,
      'files': fileUrls,
      'class_name': className,
    };

    final response = await supabase
        .from('logs')
        .insert(insertData)
        .select()
        .single();
    return Log.fromMap(response);
  }
}
