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
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated';
    }

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    final conversationId = const Uuid().v4();
    
    final conversation = Conversation(
      id: conversationId,
      title: title,
      description: description,
      createdAt: timestamp,
      updatedAt: timestamp,
      isGroup: isGroup,
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
        'is_group': isGroup,
        'created_by': currentUser.id,
        'created_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
      });

      // Add current user as participant
      final participantId = const Uuid().v4();
      await _supabase.from('conversation_participants').insert({
        'id': participantId,
        'conversation_id': conversationId,
        'user_id': currentUser.id,
        'joined_at': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String(),
      });

      // Save participant locally
      await _db.participantDao.addParticipant(Participant(
        id: participantId,
        conversationId: conversationId,
        userId: currentUser.id,
        joinedAt: timestamp,
        isAdmin: true,
        isSynced: true,
      ));

      // Mark conversation as synced
      await _db.conversationDao.markConversationAsSynced(conversationId);
      
      print('Conversation synced to backend: $conversationId');
    } catch (e) {
      print('Error syncing conversation to backend: $e');
      // Conversation stays in local DB with isSynced=false for retry later
    }

    return conversation;
  }

  /// Get all conversations
  Future<List<Conversation>> getAllConversations() async {
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

  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    await _db.conversationDao.deleteConversation(id);
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

  /// Get participants in a conversation
  Future<List<Participant>> getParticipants(String conversationId) async {
    return _db.participantDao.getParticipantsByConversation(conversationId);
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
