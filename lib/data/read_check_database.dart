import 'package:sekolahbinekas/data/user_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/read_check.dart';

class ReadCheckDatabase {
  final supabase = Supabase.instance.client;

  Future<void> addReadCheck(List<String> messageIds) async {
    final id = await UserDatabase().getCurrentUserId();
    try {
      await supabase
          .from('read_check')
          .insert(
            messageIds
                .map((messageId) => {'auth_id': id, 'message_id': messageId})
                .toList(),
          );
    } catch (e) {
      // Skip error silently
    }
  }

  Future<List<String>> whichMessagesIHaventRead(List<String> messageIds) async {
    final id = await UserDatabase().getCurrentUserId();
    final readChecks =
        await supabase
                .from('read_check')
                .select('message_id')
                .eq('auth_id', id)
                .inFilter('message_id', messageIds)
            as List<dynamic>;

    final readMessageIds = readChecks
        .map((rc) => rc['message_id'] as String)
        .toSet();
    return messageIds.where((id) => !readMessageIds.contains(id)).toList();
  }

  Future<List<ReadCheck>> getReadCheck(String messageId) async {
    final readCheck =
        await supabase.from('read_check').select().eq('message_id', messageId)
            as List<dynamic>;

    final authIds = readCheck.map((rc) => rc['auth_id']).toList();
    final users = authIds.isNotEmpty
        ? await supabase
                  .from('users_public')
                  .select('auth_id, display_name, profile_picture')
                  .inFilter('auth_id', authIds)
              as List<dynamic>
        : <dynamic>[];

    const defaultProfilePicture = 'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg';

    return readCheck.map((rc) {
      final user = users.firstWhere(
        (u) => u['auth_id'] == rc['auth_id'],
        orElse: () => {
          'auth_id': rc['auth_id'],
          'display_name': 'Unknown',
          'profile_picture': defaultProfilePicture,
        },
      );
      return ReadCheck(
        id: rc['id'],
        createdAt: DateTime.parse(rc['created_at']),
        authId: rc['auth_id'],
        messageId: rc['message_id'],
        display_name: (user['display_name'] ?? '').isEmpty ? 'Unknown' : user['display_name'],
        profile_picture: (user['profile_picture'] ?? '').isEmpty ? defaultProfilePicture : user['profile_picture'],
      );
    }).toList();
  }


  Future<bool> updateMessagesStatus(List<String> messageIds) async {
    final haventReadMessageIds = await whichMessagesIHaventRead(messageIds);
    if (haventReadMessageIds.isEmpty) return true;
    await addReadCheck(haventReadMessageIds);
    return true;
  }
}
