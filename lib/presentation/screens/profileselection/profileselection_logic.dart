import 'package:sekolahbinekas/models/user_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSelectionLogic{
    Future<void> logout() async {
    try {
      Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notifications_permission_requested');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      UserCache.clear();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}