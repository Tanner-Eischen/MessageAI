import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/conversation_dao.dart';
import 'package:messageai/data/drift/daos/message_dao.dart';
import 'package:messageai/data/drift/daos/pending_outbox_dao.dart';

/// Provides the main database instance
final appDbProvider = Provider<AppDb>((ref) {
  return AppDb.instance;
});

/// Provides the ConversationDao
final conversationDaoProvider = Provider<ConversationDao>((ref) {
  final db = ref.watch(appDbProvider);
  return ConversationDao(db);
});

/// Provides the MessageDao
final messageDaoProvider = Provider<MessageDao>((ref) {
  final db = ref.watch(appDbProvider);
  return MessageDao(db);
});

/// Provides the PendingOutboxDao
final pendingOutboxDaoProvider = Provider<PendingOutboxDao>((ref) {
  final db = ref.watch(appDbProvider);
  return PendingOutboxDao(db);
});

/// Stream of all conversations (watching for changes)
final conversationsStreamProvider = StreamProvider<List<Conversation>>((ref) async* {
  final dao = ref.watch(conversationDaoProvider);
  
  // Initial load
  yield await dao.getAllConversations();
  
  // TODO: Set up watch stream for real-time updates
  // For now, update every time this is accessed
});

/// Stream of messages for a specific conversation
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) async* {
  final dao = ref.watch(messageDaoProvider);
  
  // Initial load
  yield await dao.getMessagesByConversation(conversationId);
  
  // TODO: Set up watch stream for real-time updates
});

/// Stream of pending operations count (for UI indicators)
final pendingOperationsCountProvider = StreamProvider<int>((ref) async* {
  final dao = ref.watch(pendingOutboxDaoProvider);
  
  // Initial load
  yield await dao.getPendingOperationCount();
  
  // TODO: Set up periodic check or subscription
});

/// Check if there are any pending operations
final hasPendingOperationsProvider = FutureProvider<bool>((ref) async {
  final dao = ref.watch(pendingOutboxDaoProvider);
  return dao.hasPendingOperations();
});
