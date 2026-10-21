import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/models/user_cache.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sekolahbinekas/data/image_database.dart';

class ProfileLogic {
  Future<void> updateProfile(String? displayName, File? profilePicture) async {
    try {
      String? profilePictureUrl;
      if (profilePicture != null) {
        List<String> uploadedUrls = await ImageDatabase().uploadImages([profilePicture]);
        if (uploadedUrls.isNotEmpty) {
          profilePictureUrl = uploadedUrls.first;
          String oldProfilePictureUrl = await UserDatabase().getCurrentUserProfilePicture() ?? '';
          if (oldProfilePictureUrl.isNotEmpty) {
            await ImageDatabase().deleteImage([oldProfilePictureUrl]);
          }
        }
      }

      await UserDatabase().updateUserData(displayName, profilePictureUrl);
      // Optionally, refresh the user data in the app
      await UserDatabase().getCurrentUserData(forceRefresh: true);
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

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
