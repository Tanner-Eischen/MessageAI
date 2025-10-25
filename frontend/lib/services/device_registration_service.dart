import 'dart:io' show Platform;
import 'package:messageai/data/remote/supabase_client.dart';

/// Service for registering and managing device tokens with the backend
class DeviceRegistrationService {
  /// Register or update device token in Supabase
  Future<void> registerDeviceToken(String token) async {
    try {
      final supabase = SupabaseClientProvider.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        print('⚠️ Cannot register device: user not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Determine platform
      String platform;
      if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else {
        platform = 'web';
      }
      
      print('📱 Registering device token...');
      print('   User ID: $userId');
      print('   Platform: $platform');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Use secure function to bypass RLS issues
      await supabase.rpc('upsert_device_token', params: {
        'p_fcm_token': token,
        'p_platform': platform,
      });
      
      print('✅ Device token registered successfully!');
    } catch (e) {
      print('❌ Failed to register device token: $e');
      rethrow;
    }
  }
  
  /// Unregister device token (e.g., on logout)
  Future<void> unregisterDeviceToken(String token) async {
    try {
      final supabase = SupabaseClientProvider.client;
      
      print('🗑️ Unregistering device token...');
      
      await supabase
          .from('profile_devices')
          .delete()
          .eq('fcm_token', token);
      
      print('✅ Device token unregistered');
    } catch (e) {
      print('❌ Failed to unregister device token: $e');
      rethrow;
    }
  }
  
  /// Update last seen timestamp for device
  Future<void> updateDeviceLastSeen(String token) async {
    try {
      final supabase = SupabaseClientProvider.client;
      
      print('🔄 Updating last_seen for token: ${token.substring(0, 20)}...');
      
      final response = await supabase
          .from('profile_devices')
          .update({
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('fcm_token', token)
          .select();
      
      if (response.isEmpty) {
        print('⚠️ No device found with that token - device may not be registered');
      } else {
        print('✅ Device last_seen updated successfully');
      }
    } catch (e) {
      print('❌ Failed to update device last_seen: $e');
      // Don't rethrow - this is not critical
    }
  }
}
