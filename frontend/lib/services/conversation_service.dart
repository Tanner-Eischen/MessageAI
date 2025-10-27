import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class ConversationService {
  static final ConversationService _instance =
      ConversationService._internal();

  factory ConversationService() {
    return _instance;
  }

  ConversationService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;

  /// Create a new conversation
  Future<Conversation> createConversation({
    required String title,
    String? description,
    bool isGroup = false,
    List<String>? participantUserIds, // Additional participants to add
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated';
    }

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    final conversationId = const Uuid().v4();
    
    // Determine if it's a group based on participant count
    final actualIsGroup = isGroup || (participantUserIds != null && participantUserIds.length > 1);
    
    final conversation = Conversation(
      id: conversationId,
      title: title,
      description: description,
      createdAt: timestamp,
      updatedAt: timestamp,
      isGroup: actualIsGroup,
      lastMessageAt: timestamp,
      isSynced: false,
    );

    // Save to local database first (optimistic UI)
    await _db.conversationDao.upsertConversation(conversation);

    // Sync to backend
    try {
      // Create conversation in backend
      await _supabase.from('conversations').insert({
        'id': conversationId,
        'title': title,
        'description': description,
        'is_group': actualIsGroup,
        'created_by': currentUser.id,
        'created_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
      });

      // Add current user as participant (admin)
      final currentUserParticipantId = const Uuid().v4();
      await _supabase.from('conversation_participants').insert({
        'id': currentUserParticipantId,
        'conversation_id': conversationId,
        'user_id': currentUser.id,
        'joined_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
        'is_admin': true,
      });

      // Save current user participant locally
      await _db.participantDao.addParticipant(Participant(
        id: currentUserParticipantId,
        conversationId: conversationId,
        userId: currentUser.id,
        joinedAt: timestamp,
        isAdmin: true,
        isSynced: true,
      ));

      // Add additional participants if provided
      if (participantUserIds != null && participantUserIds.isNotEmpty) {
        for (final userId in participantUserIds) {
          final participantId = const Uuid().v4();
          await _supabase.from('conversation_participants').insert({
            'id': participantId,
            'conversation_id': conversationId,
            'user_id': userId,
            'joined_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
            'is_admin': false,
          });

          // Save participant locally
          await _db.participantDao.addParticipant(Participant(
            id: participantId,
            conversationId: conversationId,
            userId: userId,
            joinedAt: timestamp,
            isAdmin: false,
            isSynced: true,
          ));
        }
      }

      // Mark conversation as synced
      await _db.conversationDao.markConversationAsSynced(conversationId);
      
      print('Conversation synced to backend: $conversationId');
    } catch (e) {
      print('Error syncing conversation to backend: $e');
      // Conversation stays in local DB with isSynced=false for retry later
    }

    return conversation;
  }

  /// Sync conversations from backend
  Future<void> syncConversations() async {
    try {
      print('🔄 Syncing conversations from backend...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated, skipping sync');
        return;
      }

      // Fetch conversations where user is a participant
      final response = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUser.id);

      final conversationIds = (response as List)
          .map((p) => p['conversation_id'] as String)
          .toList();

      if (conversationIds.isEmpty) {
        print('ℹ️  No conversations found for user');
        return;
      }

      // Fetch full conversation details
      final conversationsResponse = await _supabase
          .from('conversations')
          .select('*')
          .in_('id', conversationIds);

      print('📥 Fetched ${(conversationsResponse as List).length} conversations from backend');

      // Save to local database
      for (final convData in conversationsResponse) {
        final conversation = Conversation(
          id: convData['id'] as String,
          title: convData['title'] as String,
          description: convData['description'] as String?,
          createdAt: DateTime.parse(convData['created_at'] as String)
              .millisecondsSinceEpoch ~/
              1000,
          updatedAt: DateTime.parse(convData['updated_at'] as String)
              .millisecondsSinceEpoch ~/
              1000,
          isGroup: convData['is_group'] as bool? ?? false,
          lastMessageAt: convData['last_message_at'] != null
              ? DateTime.parse(convData['last_message_at'] as String)
                  .millisecondsSinceEpoch ~/
                  1000
              : DateTime.parse(convData['created_at'] as String)
                  .millisecondsSinceEpoch ~/
                  1000,
          isSynced: true,
        );

        await _db.conversationDao.upsertConversation(conversation);
      }

      print('✅ Conversations synced successfully');
    } catch (e) {
      print('❌ Error syncing conversations: $e');
    }
  }

  /// Get all conversations (with optional sync)
  Future<List<Conversation>> getAllConversations({bool syncFirst = true}) async {
    if (syncFirst) {
      await syncConversations();
    }
    return _db.conversationDao.getAllConversations();
  }

  /// Get recent conversations
  Future<List<Conversation>> getRecentConversations({int limit = 20}) async {
    return _db.conversationDao.getRecentConversations(limit: limit);
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String id) async {
    return _db.conversationDao.getConversationById(id);
  }

  /// Delete conversation (local and remote)
  Future<void> deleteConversation(String id) async {
    final currentUser = _supabase.auth.currentUser;
    print('━' * 60);
    print('🗑️ DELETING CONVERSATION');
    print('━' * 60);
    print('Conversation ID: $id');
    print('User ID: ${currentUser?.id}');
    
    // Delete from local database first
    await _db.conversationDao.deleteConversation(id);
    print('✅ Deleted from local database');
    
    // Try to delete from Supabase
    try {
      print('Attempting to delete from Supabase...');
      
      // Delete from Supabase (CASCADE will delete participants and messages)
      await _supabase
          .from('conversations')
          .delete()
          .eq('id', id);
      
      print('✅ Conversation deleted from backend: $id');
      print('━' * 60);
    } catch (e) {
      print('━' * 60);
      print('❌ ERROR DELETING FROM BACKEND');
      print('━' * 60);
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      
      if (e.toString().contains('row-level security')) {
        print('🔒 RLS POLICY BLOCKING DELETE!');
        print('Solution: Run the SQL in FIX_DELETE_CONVERSATION.md');
      }
      
      print('━' * 60);
      // Already deleted locally, so this is non-critical
      // But we should rethrow so the UI can show the error
      rethrow;
    }
  }

  /// Update conversation title
  Future<void> updateConversationTitle(String id, String title) async {
    final conv = await getConversationById(id);
    if (conv != null) {
      final updated = conv.copyWith(
        title: title,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await _db.conversationDao.upsertConversation(updated);
    }
  }

  /// Count conversations
  Future<int> getConversationCount() async {
    return _db.conversationDao.getConversationCount();
  }

  /// Sync participants from backend
  Future<void> syncParticipants(String conversationId) async {
    try {
      print('🔄 Syncing participants for conversation: $conversationId');
      
      // Fetch participants from backend
      final response = await _supabase
          .from('conversation_participants')
          .select('*')
          .eq('conversation_id', conversationId);

      print('📥 Fetched ${(response as List).length} participants from backend');

      // Save participants to local database
      for (final partData in response) {
        final participant = Participant(
          id: partData['id'] as String,
          conversationId: partData['conversation_id'] as String,
          userId: partData['user_id'] as String,
          joinedAt: DateTime.parse(partData['joined_at'] as String)
              .millisecondsSinceEpoch ~/
              1000,
          isAdmin: partData['is_admin'] as bool? ?? false,
          isSynced: true,
        );
        
        await _db.participantDao.addParticipant(participant);
      }

      print('✅ Participants synced successfully');
    } catch (e) {
      print('❌ Error syncing participants: $e');
    }
  }

  /// Get participants in a conversation
  Future<List<Participant>> getParticipants(String conversationId, {bool syncFirst = true}) async {
    if (syncFirst) {
      await syncParticipants(conversationId);
    }
    return _db.participantDao.getParticipantsByConversation(conversationId);
  }
  
  /// Get participant profile from Supabase by user ID
  Future<Map<String, dynamic>?> getParticipantProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_id, username, email, avatar_url, display_name')
          .eq('user_id', userId)
          .single();
      
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching profile for $userId: $e');
      return null;
    }
  }

  /// Add participant to conversation
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final participantId = const Uuid().v4();
    
    final participant = Participant(
      id: participantId,
      conversationId: conversationId,
      userId: userId,
      joinedAt: now,
      isAdmin: false,
      isSynced: false,
    );
    
    // Save to local database first (optimistic UI)
    await _db.participantDao.addParticipant(participant);
    
    // Sync to backend
    try {
      await _supabase.from('conversation_participants').insert({
        'id': participantId,
        'conversation_id': conversationId,
        'user_id': userId,
        'joined_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      });
      
      print('Participant added to backend: $userId');
    } catch (e) {
      print('Error syncing participant to backend: $e');
    }
  }

  /// Remove participant from conversation
  Future<void> removeParticipant(String conversationId, String userId) async {
    await _db.participantDao.removeParticipant(conversationId, userId);
  }

  /// Add current user as participant to conversation
  Future<void> addCurrentUserAsParticipant(String conversationId) async {
    // This would typically be called after creating a conversation
    // For now, we'll add the creator automatically in createConversation
  }

  /// Get the latest message for a conversation
  Future<Message?> getLatestMessage(String conversationId) async {
    return _db.messageDao.getLatestMessageForConversation(conversationId);
  }
}
