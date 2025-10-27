import 'package:messageai/data/remote/supabase_client.dart';

/// Model for a user/contact
class Contact {
  final String userId;
  final String? email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  Contact({
    required this.userId,
    this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      userId: json['user_id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get displayLabel => displayName ?? username ?? email ?? 'User ${userId.substring(0, 8)}';
  String get initials {
    final name = displayLabel;
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

/// Service for fetching contacts/users
class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final _supabase = SupabaseClientProvider.client;

  /// Get all users (potential contacts)
  Future<List<Contact>> getAllContacts() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('profiles')
          .select('user_id, email, username, display_name, avatar_url')
          .neq('user_id', currentUserId) // Exclude current user
          .order('username', ascending: true);

      return (response as List)
          .map((json) => Contact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching contacts: $e');
      return [];
    }
  }

  /// Search contacts by name or email
  Future<List<Contact>> searchContacts(String query) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      if (query.isEmpty) return getAllContacts();

      final response = await _supabase
          .from('profiles')
          .select('user_id, email, username, display_name, avatar_url')
          .neq('user_id', currentUserId)
          .or('username.ilike.%$query%,email.ilike.%$query%,display_name.ilike.%$query%')
          .order('username', ascending: true);

      return (response as List)
          .map((json) => Contact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error searching contacts: $e');
      return [];
    }
  }

  /// Get contact by user ID
  Future<Contact?> getContact(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_id, email, username, display_name, avatar_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Contact.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching contact: $e');
      return null;
    }
  }
}

