import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/core/errors/app_error.dart';
import 'package:messageai/core/errors/error_handler.dart';

/// Service for handling avatar uploads and management
class AvatarService {
  static final AvatarService _instance = AvatarService._internal();

  factory AvatarService() {
    return _instance;
  }

  AvatarService._internal();

  final _supabase = SupabaseClientProvider.client;
  final _errorHandler = ErrorHandler();
  final _imagePicker = ImagePicker();

  /// Pick an image from gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image;
    } catch (error, stackTrace) {
      throw _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Pick Image',
      );
    }
  }

  /// Pick an image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image;
    } catch (error, stackTrace) {
      throw _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Take Photo',
      );
    }
  }

  /// Upload avatar to Supabase Storage and update profile
  Future<String> uploadAvatar(XFile imageFile) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw AuthError.sessionExpired();
      }

      print('📤 Uploading avatar for user: ${currentUser.id}');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '${currentUser.id}/avatar_$timestamp.$extension';

      // Read file bytes
      final Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        fileBytes = await File(imageFile.path).readAsBytes();
      }

      print('📁 File size: ${fileBytes.length} bytes');
      print('📁 File name: $fileName');

      // Delete old avatar if exists
      await _deleteOldAvatar(currentUser.id);

      // Upload to Supabase Storage
      final uploadPath = await _supabase.storage
          .from('avatars')
          .uploadBinary(fileName, fileBytes);

      print('✅ Avatar uploaded: $uploadPath');

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      print('🔗 Public URL: $publicUrl');

      // Update profile with new avatar URL
      await _updateProfileAvatar(currentUser.id, publicUrl);

      return publicUrl;
    } catch (error, stackTrace) {
      print('❌ Error uploading avatar: $error');
      if (error is AppError) {
        rethrow;
      }
      throw _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Upload Avatar',
      );
    }
  }

  /// Delete old avatar files for a user
  Future<void> _deleteOldAvatar(String userId) async {
    try {
      // List all files in user's folder
      final files = await _supabase.storage
          .from('avatars')
          .list(path: userId);

      // Delete each file
      for (final file in files) {
        final filePath = '$userId/${file.name}';
        await _supabase.storage
            .from('avatars')
            .remove([filePath]);
        print('🗑️  Deleted old avatar: $filePath');
      }
    } catch (e) {
      print('⚠️  Error deleting old avatar (non-critical): $e');
      // Don't throw - old avatar deletion is non-critical
    }
  }

  /// Update profile table with new avatar URL
  Future<void> _updateProfileAvatar(String userId, String avatarUrl) async {
    try {
      await _supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);

      print('✅ Profile updated with new avatar URL');
    } catch (error, stackTrace) {
      throw _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Update Profile Avatar',
      );
    }
  }

  /// Get avatar URL for a user
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['avatar_url'] != null) {
        return response['avatar_url'] as String;
      }
      return null;
    } catch (error, stackTrace) {
      print('⚠️  Error fetching avatar URL: $error');
      // Return null instead of throwing - missing avatar is not critical
      return null;
    }
  }

  /// Delete avatar for current user
  Future<void> deleteAvatar() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw AuthError.sessionExpired();
      }

      print('🗑️  Deleting avatar for user: ${currentUser.id}');

      // Delete from storage
      await _deleteOldAvatar(currentUser.id);

      // Update profile to remove avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', currentUser.id);

      print('✅ Avatar deleted successfully');
    } catch (error, stackTrace) {
      if (error is AppError) {
        rethrow;
      }
      throw _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Delete Avatar',
      );
    }
  }

  /// Get current user's avatar URL
  Future<String?> getCurrentUserAvatar() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return null;
    }
    return getAvatarUrl(currentUser.id);
  }
}

