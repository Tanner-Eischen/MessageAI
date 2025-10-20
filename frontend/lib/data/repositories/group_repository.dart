import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/conversation_dao.dart';
import 'package:messageai/data/drift/daos/participant_dao.dart';
import 'package:uuid/uuid.dart';

/// Repository for group operations
class GroupRepository {
  final ConversationDao _conversationDao;
  final ParticipantDao _participantDao;

  GroupRepository({
    required ConversationDao conversationDao,
    required ParticipantDao participantDao,
  })  : _conversationDao = conversationDao,
        _participantDao = participantDao;

  /// Create a new group conversation
  Future<Conversation> createGroup({
    required String title,
    required String description,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    const uuid = Uuid();
    final conversationId = uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create conversation
    final conversation = Conversation(
      id: conversationId,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      isGroup: true,
      isSynced: false,
    );
    
    await _conversationDao.upsertConversation(conversation);
    
    // Add creator as admin
    final creatorParticipant = Participant(
      id: uuid.v4(),
      conversationId: conversationId,
      userId: creatorId,
      joinedAt: now,
      isAdmin: true,
      isSynced: false,
    );
    
    await _participantDao.addParticipant(creatorParticipant);
    
    // Add other members
    final participants = memberIds.map((userId) {
      return Participant(
        id: uuid.v4(),
        conversationId: conversationId,
        userId: userId,
        joinedAt: now,
        isAdmin: false,
        isSynced: false,
      );
    }).toList();
    
    await _participantDao.addParticipants(participants);
    
    return conversation;
  }

  /// Get group details with members
  Future<(Conversation, List<Participant>)> getGroupWithMembers(String groupId) async {
    final conversation = await _conversationDao.getConversationById(groupId);
    if (conversation == null) {
      throw Exception('Group not found: $groupId');
    }
    
    final participants = await _participantDao.getParticipantsByConversation(groupId);
    
    return (conversation, participants);
  }

  /// Update group info
  Future<void> updateGroupInfo({
    required String groupId,
    String? title,
    String? description,
  }) async {
    // This would require a Conversation update method in ConversationDao
    // For now, creating a placeholder
    // TODO: Implement in ConversationDao
  }

  /// Add member to group
  Future<void> addGroupMember({
    required String groupId,
    required String userId,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Check if already a member
    final existing = await _participantDao.getParticipant(groupId, userId);
    if (existing != null) {
      throw Exception('User is already a member of this group');
    }
    
    final participant = Participant(
      id: uuid.v4(),
      conversationId: groupId,
      userId: userId,
      joinedAt: now,
      isAdmin: false,
      isSynced: false,
    );
    
    await _participantDao.addParticipant(participant);
  }

  /// Remove member from group
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    await _participantDao.removeParticipant(groupId, userId);
  }

  /// Promote member to admin
  Future<void> promoteToAdmin({
    required String groupId,
    required String userId,
  }) async {
    final participant = await _participantDao.getParticipant(groupId, userId);
    if (participant == null) {
      throw Exception('Member not found in group');
    }
    
    await _participantDao.promoteToAdmin(participant.id);
  }

  /// Demote admin to member
  Future<void> demoteFromAdmin({
    required String groupId,
    required String userId,
  }) async {
    final participant = await _participantDao.getParticipant(groupId, userId);
    if (participant == null) {
      throw Exception('Member not found in group');
    }
    
    await _participantDao.demoteFromAdmin(participant.id);
  }

  /// Get user's groups
  Future<List<Conversation>> getUserGroups(String userId) async {
    final allConversations = await _conversationDao.getAllConversations();
    
    // Filter to only groups where user is a participant
    final userGroups = <Conversation>[];
    
    for (final conversation in allConversations) {
      if (conversation.isGroup) {
        final isParticipant = await _participantDao.isParticipant(
          conversation.id,
          userId,
        );
        if (isParticipant) {
          userGroups.add(conversation);
        }
      }
    }
    
    return userGroups;
  }

  /// Leave group
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _participantDao.removeParticipant(groupId, userId);
  }

  /// Delete group (admin only)
  Future<void> deleteGroup(String groupId) async {
    // Remove all participants
    await _participantDao.removeConversationParticipants(groupId);
    
    // Delete conversation
    await _conversationDao.deleteConversation(groupId);
  }

  /// Get group members count
  Future<int> getGroupMemberCount(String groupId) async {
    return _participantDao.getParticipantCount(groupId);
  }

  /// Check if user is group admin
  Future<bool> isUserGroupAdmin(String groupId, String userId) async {
    return _participantDao.isAdmin(groupId, userId);
  }
}
