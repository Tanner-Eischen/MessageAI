import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class DeviceTokenService {
  final _supabase = SupabaseClientProvider.client;

  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Cannot register device token: user not authenticated');
        return;
      }

      final platform = _getPlatform();

      await _supabase.from('profile_devices').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'platform': platform,
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');

      print('Device token registered successfully: $fcmToken (platform: $platform)');
    } catch (e) {
      print('Error registering device token: $e');
      rethrow;
    }
  }

  Future<void> unregisterDeviceToken(String fcmToken) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Cannot unregister device token: user not authenticated');
        return;
      }

      await _supabase
          .from('profile_devices')
          .delete()
          .eq('fcm_token', fcmToken)
          .eq('user_id', userId);

      print('Device token unregistered successfully: $fcmToken');
    } catch (e) {
      print('Error unregistering device token: $e');
    }
  }

  Future<void> updateDeviceLastSeen(String fcmToken) async {
    try {
      await _supabase
          .from('profile_devices')
          .update({
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('fcm_token', fcmToken);

      print('Device last_seen updated');
    } catch (e) {
      print('Error updating device last_seen: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _supabase
          .from('profile_devices')
          .select('id, fcm_token, platform, last_seen, created_at')
          .eq('user_id', userId)
          .order('last_seen', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user devices: $e');
      return [];
    }
  }

  Future<void> cleanupStaleDevices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      final staleDate = DateTime.now().subtract(const Duration(days: 90));

      await _supabase
          .from('profile_devices')
          .delete()
          .eq('user_id', userId)
          .lt('last_seen', staleDate.toIso8601String());

      print('Stale devices cleaned up (older than 90 days)');
    } catch (e) {
      print('Error cleaning up stale devices: $e');
    }
  }

  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }
}
