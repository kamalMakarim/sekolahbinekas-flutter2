import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as local_user;
import '../models/user_cache.dart';

class UserDatabase {
  final supabase = Supabase.instance.client;

  Future<local_user.User?> getCurrentUserData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && UserCache.user != null) {
      return UserCache.user;
    }

    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final id = authUser.id;

    // Get public data
    final publicResponse = await supabase
        .from('users_public')
        .select('id, display_name, profile_picture')
        .eq('auth_id', id)
        .maybeSingle();

    // Get private data
    final privateResponse = await supabase
        .from('users_private')
        .select('role, class_name')
        .eq('auth_id', id)
        .maybeSingle();

    //get zipline token
    final ziplineResponse = await supabase
        .from('user_zipline_tokens')
        .select('zipline_token')
        .eq('auth_id', id)
        .maybeSingle();

    if (publicResponse == null || privateResponse == null) {
      throw Exception('Error fetching user data');
    }

    final user = local_user.User(
      id: id,
      display_name: publicResponse['display_name'],
      role: privateResponse['role'],
      class_name: privateResponse['class_name'] ?? '',
      profile_picture:
          (publicResponse['profile_picture'] == null ||
              publicResponse['profile_picture'].toString().isEmpty)
          ? 'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg'
          : publicResponse['profile_picture'],
      zipline_token: ziplineResponse != null
          ? ziplineResponse['zipline_token'] as String?
          : null,
    );

    UserCache.setUser(user);
    return user;
  }

  Future<void> updateUserData(
    String? displayName,
    String? profilePciture,
  ) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('User not logged in');

    final id = authUser.id;

    final response = await supabase
        .from('users_public')
        .update({
          'display_name': ?displayName,
          'profile_picture': ?profilePciture,
        })
        .eq('auth_id', id)
        .select();
    if (response.isEmpty) {
      throw Exception('Error updating user data');
    }

    // Update the cached user data
    if (UserCache.user != null) {
      UserCache.setUser(
        local_user.User(
          id: id,
          display_name: displayName ?? UserCache.user!.display_name,
          role: UserCache.user!.role,
          class_name: UserCache.user!.class_name,
          profile_picture: profilePciture ?? UserCache.user!.profile_picture,
        ),
      );
    }
  }

  Future<String> getCurrentUserDisplayName() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.display_name;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<String?> getCurrentUserProfilePicture() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.profile_picture;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<String> getCurrentUserId() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.id;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<String?> getCurrentUserZiplineToken() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.zipline_token;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<String?> getCurrentUserClassName() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.class_name;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<String> getUserRole() async {
    final user = await getCurrentUserData();
    if (user != null) {
      return user.role ?? 'parent';
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<local_user.User?> getUserPublicDataByAuthId(String? authId) async {
    if (authId == null || authId.isEmpty) return null;

    final response = await supabase
        .from('users_public')
        .select('id, display_name, profile_picture')
        .eq('auth_id', authId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return local_user.User(
      id: authId,
      display_name: response['display_name'],
      profile_picture:
          (response['profile_picture'] == null ||
              response['profile_picture'].toString().isEmpty)
          ? 'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg'
          : response['profile_picture'],
    );
  }
}
