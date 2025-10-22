import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'dart:math';

class GroupService {
  static final GroupService _instance = GroupService._internal();

  factory GroupService() {
    return _instance;
  }

  GroupService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;

  Future<void> promoteToAdmin({
    required String conversationId,
    required String userId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final currentUserParticipant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (currentUserParticipant == null || !currentUserParticipant.isAdmin) {
      throw Exception('Only admins can promote members');
    }

    await _db.participantDao.updateAdminStatus(conversationId, userId, true);

    try {
      await _supabase
          .from('participants')
          .update({'is_admin': true})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error syncing admin promotion: $e');
    }
  }

  Future<void> demoteFromAdmin({
    required String conversationId,
    required String userId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final currentUserParticipant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (currentUserParticipant == null || !currentUserParticipant.isAdmin) {
      throw Exception('Only admins can demote members');
    }

    final adminCount = await _db.participantDao.getAdminCount(conversationId);
    if (adminCount <= 1) {
      throw Exception('Cannot demote the last admin');
    }

    await _db.participantDao.updateAdminStatus(conversationId, userId, false);

    try {
      await _supabase
          .from('participants')
          .update({'is_admin': false})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error syncing admin demotion: $e');
    }
  }

  Future<String> generateInviteCode(String conversationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final participant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (participant == null || !participant.isAdmin) {
      throw Exception('Only admins can generate invite links');
    }

    final inviteCode = _generateRandomCode(8);

    await _db.conversationDao.updateInviteCode(conversationId, inviteCode);

    try {
      await _supabase
          .from('conversations')
          .update({'invite_code': inviteCode})
          .eq('id', conversationId);
    } catch (e) {
      print('Error syncing invite code: $e');
    }

    return inviteCode;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<Conversation?> joinGroupByInviteCode(String inviteCode) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final conversation = await _db.conversationDao.getConversationByInviteCode(inviteCode);

    if (conversation == null) {
      throw Exception('Invalid invite code');
    }

    final existingParticipant = await _db.participantDao.getParticipant(
      conversation.id,
      currentUser.id,
    );

    if (existingParticipant != null) {
      return conversation;
    }

    final participantId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final participant = Participant(
      id: participantId,
      conversationId: conversation.id,
      userId: currentUser.id,
      joinedAt: now,
      isAdmin: false,
      isSynced: false,
    );

    await _db.participantDao.insertParticipant(participant);

    try {
      await _supabase.from('participants').insert({
        'id': participantId,
        'conversation_id': conversation.id,
        'user_id': currentUser.id,
        'joined_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        'is_admin': false,
      });

      await _db.participantDao.markParticipantAsSynced(participantId);
    } catch (e) {
      print('Error syncing participant join: $e');
    }

    return conversation;
  }

  Future<void> updateGroupInfo({
    required String conversationId,
    String? title,
    String? description,
    String? avatarUrl,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final participant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (participant == null || !participant.isAdmin) {
      throw Exception('Only admins can update group info');
    }

    await _db.conversationDao.updateGroupInfo(
      conversationId,
      title: title,
      description: description,
      avatarUrl: avatarUrl,
    );

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _supabase
            .from('conversations')
            .update(updates)
            .eq('id', conversationId);
      }
    } catch (e) {
      print('Error syncing group info: $e');
    }
  }

  Future<void> leaveGroup(String conversationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final participant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (participant == null) {
      throw Exception('Not a member of this group');
    }

    if (participant.isAdmin) {
      final adminCount = await _db.participantDao.getAdminCount(conversationId);
      if (adminCount <= 1) {
        final participantCount = await _db.participantDao.getParticipantCount(conversationId);
        if (participantCount > 1) {
          throw Exception('Cannot leave: You are the only admin. Promote another member first.');
        }
      }
    }

    await _db.participantDao.removeParticipant(conversationId, currentUser.id);

    try {
      await _supabase
          .from('participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUser.id);
    } catch (e) {
      print('Error syncing leave group: $e');
    }
  }

  Future<void> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final currentUserParticipant = await _db.participantDao.getParticipant(
      conversationId,
      currentUser.id,
    );

    if (currentUserParticipant == null || !currentUserParticipant.isAdmin) {
      throw Exception('Only admins can remove members');
    }

    if (userId == currentUser.id) {
      throw Exception('Use leave group to remove yourself');
    }

    await _db.participantDao.removeParticipant(conversationId, userId);

    try {
      await _supabase
          .from('participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error syncing member removal: $e');
    }
  }

  Future<List<Participant>> getGroupMembers(String conversationId) async {
    return _db.participantDao.getParticipantsByConversation(conversationId);
  }

  Future<bool> isAdmin(String conversationId, String userId) async {
    final participant = await _db.participantDao.getParticipant(
      conversationId,
      userId,
    );
    return participant?.isAdmin ?? false;
  }
}
