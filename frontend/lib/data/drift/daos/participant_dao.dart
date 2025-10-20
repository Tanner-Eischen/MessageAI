import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'participant_dao.g.dart';

@DriftAccessor(tables: [Participants])
class ParticipantDao extends DatabaseAccessor<AppDb> {
  ParticipantDao(AppDb db) : super(db);

  /// Get all participants in a conversation
  Future<List<Participant>> getParticipantsByConversation(String conversationId) async {
    return (select(participants)
          ..where((p) => p.conversationId.equals(conversationId)))
        .get();
  }

  /// Get participant by ID
  Future<Participant?> getParticipantById(String id) async {
    return (select(participants)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get participant by conversation ID and user ID
  Future<Participant?> getParticipant(String conversationId, String userId) async {
    return (select(participants)
          ..where((p) =>
              p.conversationId.equals(conversationId) & p.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Add participant to conversation
  Future<void> addParticipant(Participant participant) async {
    await into(participants).insert(participant);
  }

  /// Batch add participants
  Future<void> addParticipants(List<Participant> parts) async {
    await batch((batch) {
      batch.insertAll(participants, parts, mode: InsertMode.insertOrReplace);
    });
  }

  /// Remove participant from conversation
  Future<int> removeParticipant(String conversationId, String userId) async {
    return (delete(participants)
          ..where((p) =>
              p.conversationId.equals(conversationId) & p.userId.equals(userId)))
        .go();
  }

  /// Remove participant by ID
  Future<int> removeParticipantById(String id) async {
    return (delete(participants)..where((p) => p.id.equals(id))).go();
  }

  /// Remove all participants from conversation
  Future<int> removeConversationParticipants(String conversationId) async {
    return (delete(participants)..where((p) => p.conversationId.equals(conversationId)))
        .go();
  }

  /// Promote participant to admin
  Future<void> promoteToAdmin(String id) async {
    await (update(participants)..where((p) => p.id.equals(id)))
        .write(const ParticipantsCompanion(isAdmin: Value(true)));
  }

  /// Demote participant from admin
  Future<void> demoteFromAdmin(String id) async {
    await (update(participants)..where((p) => p.id.equals(id)))
        .write(const ParticipantsCompanion(isAdmin: Value(false)));
  }

  /// Get admin count for a conversation
  Future<int> getAdminCount(String conversationId) async {
    final result = await (select(participants)
          ..where((p) =>
              p.conversationId.equals(conversationId) & p.isAdmin.equals(true))
          ..addColumns([countAll()]))
        .map((row) => row.read<int>(countAll()))
        .getSingle();
    return result;
  }

  /// Get participant count for a conversation
  Future<int> getParticipantCount(String conversationId) async {
    final result = await (select(participants)
          ..where((p) => p.conversationId.equals(conversationId))
          ..addColumns([countAll()]))
        .map((row) => row.read<int>(countAll()))
        .getSingle();
    return result;
  }

  /// Check if user is participant in conversation
  Future<bool> isParticipant(String conversationId, String userId) async {
    final participant = await getParticipant(conversationId, userId);
    return participant != null;
  }

  /// Check if user is admin in conversation
  Future<bool> isAdmin(String conversationId, String userId) async {
    final participant = await getParticipant(conversationId, userId);
    return participant?.isAdmin ?? false;
  }

  /// Mark participants as synced
  Future<void> markParticipantsAsSynced(List<String> ids) async {
    await batch((batch) {
      for (final id in ids) {
        batch.update(participants, const ParticipantsCompanion(isSynced: Value(true)),
            where: (p) => p.id.equals(id));
      }
    });
  }
}
