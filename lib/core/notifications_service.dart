import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sekolahbinekas/main.dart';

class NotificationsService {
  final supabase = Supabase.instance.client;

  Future<void> setupFCM() async {
    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        final prefs = await SharedPreferences.getInstance();

        // Check if we've already requested permission before
        final alreadyAsked =
            prefs.getBool('notifications_permission_requested') ?? false;

        if (!alreadyAsked) {
          final settings = await FirebaseMessaging.instance.requestPermission();
          await FirebaseMessaging.instance.getAPNSToken();

          // Save the flag so we don't ask again next time
          await prefs.setBool('notifications_permission_requested', true);

          debugPrint(
            "🔔 Notifications permission status: ${settings.authorizationStatus}",
          );
        }

        // Always get the token (new or existing)
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _setFCMToken(fcmToken);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _setFCMToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
          ),
        );
      }
    });
  }

  Future<void> _setFCMToken(String token) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return;

    await supabase.from('fcm_tokens').upsert({
      'auth_id': authUser.id,
      'fcm_token': token,
    }, onConflict: 'auth_id');
  }
}
