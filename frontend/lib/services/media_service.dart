import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:messageai/state/providers.dart';

/// Media upload progress
class MediaUploadProgress {
  final int bytesTransferred;
  final int totalBytes;
  
  MediaUploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
  });
  
  double get progress => totalBytes > 0 ? bytesTransferred / totalBytes : 0;
  double get percentage => progress * 100;
}

/// Media service for handling uploads
class MediaService {
  final Ref ref;
  
  static const String _mediaBucket = 'message-media';
  static const String _defaultBucketUrl = 
      'https://project-id.supabase.co/storage/v1/object/public/message-media/';
  
  MediaService({required this.ref});

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    final picker = ImagePicker();
    return picker.pickImage(source: ImageSource.gallery);
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    final picker = ImagePicker();
    return picker.pickImage(source: ImageSource.camera);
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage(XFile file) async {
    final supabase = ref.watch(supabaseClientProvider);
    
    try {
      // Generate unique filename
      const uuid = Uuid();
      final fileName = '${uuid.v4()}_${p.basename(file.path)}';
      final path = 'conversations/$fileName';
      
      // Read file bytes
      final fileBytes = await file.readAsBytes();
      
      // Upload to storage
      await supabase.storage
          .from(_mediaBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );
      
      // Get public URL
      final url = supabase.storage
          .from(_mediaBucket)
          .getPublicUrl(path);
      
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload image with progress tracking
  Future<String> uploadImageWithProgress(
    XFile file,
    Function(MediaUploadProgress) onProgress,
  ) async {
    final supabase = ref.watch(supabaseClientProvider);
    
    try {
      // Generate unique filename
      const uuid = Uuid();
      final fileName = '${uuid.v4()}_${p.basename(file.path)}';
      final path = 'conversations/$fileName';
      
      // Read file bytes
      final fileBytes = await file.readAsBytes();
      final totalBytes = fileBytes.length;
      
      // Simulate progress (Supabase doesn't provide built-in progress)
      // In production, use a dedicated upload library
      int bytesTransferred = 0;
      
      // Upload to storage
      await supabase.storage
          .from(_mediaBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );
      
      bytesTransferred = totalBytes;
      onProgress(MediaUploadProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
      ));
      
      // Get public URL
      final url = supabase.storage
          .from(_mediaBucket)
          .getPublicUrl(path);
      
      return url;
    } catch (e) {
      print('Error uploading image with progress: $e');
      rethrow;
    }
  }

  /// Delete image from storage
  Future<void> deleteImage(String url) async {
    final supabase = ref.watch(supabaseClientProvider);
    
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final path = pathSegments.sublist(4).join('/'); // Skip storage, v1, object, public
      
      await supabase.storage.from(_mediaBucket).remove([path]);
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Compress image before upload
  Future<File> compressImage(XFile file, {int quality = 85}) async {
    // TODO: Implement image compression using image package
    // For now, return original file
    return File(file.path);
  }
}

/// Provider for media service
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(ref: ref);
});

/// State notifier for handling media uploads
class MediaUploadNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref ref;

  MediaUploadNotifier({required this.ref}) : super(const AsyncValue.data(''));

  /// Upload image
  Future<String> uploadImage(XFile file) async {
    state = const AsyncValue.loading();
    
    try {
      final mediaService = ref.watch(mediaServiceProvider);
      final url = await mediaService.uploadImage(file);
      state = AsyncValue.data(url);
      return url;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Upload image with progress
  Future<String> uploadImageWithProgress(
    XFile file,
    Function(MediaUploadProgress) onProgress,
  ) async {
    state = const AsyncValue.loading();
    
    try {
      final mediaService = ref.watch(mediaServiceProvider);
      final url = await mediaService.uploadImageWithProgress(file, onProgress);
      state = AsyncValue.data(url);
      return url;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// State notifier provider for media uploads
final mediaUploadNotifierProvider =
    StateNotifierProvider<MediaUploadNotifier, AsyncValue<String>>((ref) {
  return MediaUploadNotifier(ref: ref);
});
