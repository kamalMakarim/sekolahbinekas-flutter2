import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/read_check_database.dart';
import '../models/message.dart';

class MessageDatabase {
  final supabase = Supabase.instance.client;

  // Get message of a specific student
  Future<List<Message>> getMessagesByStudentId(
    String studentId, {
    DateTime? before,
    int limit = 15,
  }) async {
    final query = supabase
        .from('messages')
        .select('''
        id,
        message,
        student_id,
        images,
        files,
        sender_id,
        message_type,
        created_at,
        log_id,
        users_public:sender_id (
          display_name,
          profile_picture
        )
      ''')
        .eq('student_id', studentId);

    final response = await query
        .lt(
          'created_at',
          before?.toIso8601String() ?? DateTime.now().toIso8601String(),
        )
        .order('created_at', ascending: false) // NEWEST FIRST
        .limit(limit);
    await ReadCheckDatabase().updateMessagesStatus(
      response.map((m) => m['id'] as String).toList(),
    );

    return (response as List).map((m) => Message.fromMap(m)).toList();
  }

  Future<Message> addMessage(
    String message,
    String studentId,
    List<String>? images,
    List<String>? files,
  ) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('User not logged in');

    final insertData = {
      'message': message,
      'student_id': studentId,
      'images': images,
      'files': files,
      'sender_id': authUser.id,
      'message_type': 'message',
    };

    final response = await supabase
        .from('messages')
        .insert(insertData)
        .select()
        .single();
    
    await supabase.from('read_check').insert({
      'auth_id': authUser.id,
      'message_id': response['id'],
    });

    return Message.fromMap(response);
  }

  Future<void> deleteMessage(
    String messageId,
    String messageType,
    String? logId,
  ) async {
    try {
      if (logId != null && messageType == 'log') {
        await supabase.from('logs').delete().eq('id', logId);
      } else {
        await supabase.from('messages').delete().eq('id', messageId);
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
