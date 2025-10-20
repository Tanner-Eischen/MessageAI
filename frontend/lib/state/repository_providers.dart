import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/repositories/message_repository.dart';
import 'package:messageai/data/repositories/receipt_repository.dart';
import 'package:messageai/data/repositories/group_repository.dart';
import 'package:messageai/state/database_provider.dart';
import 'package:messageai/state/providers.dart';

/// Provides the MessageRepository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final messagesApi = ref.watch(messagesApiProvider);
  final messageDao = ref.watch(messageDaoProvider);
  final outboxDao = ref.watch(pendingOutboxDaoProvider);
  
  return MessageRepository(
    messagesApi: messagesApi,
    messageDao: messageDao,
    outboxDao: outboxDao,
  );
});

/// Provides the ReceiptRepository
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final receiptsApi = ref.watch(receiptsApiProvider);
  final receiptDao = ref.watch(receiptDaoProvider);
  final outboxDao = ref.watch(pendingOutboxDaoProvider);
  
  return ReceiptRepository(
    receiptsApi: receiptsApi,
    receiptDao: receiptDao,
    outboxDao: outboxDao,
  );
});

/// Provides the GroupRepository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final conversationDao = ref.watch(conversationDaoProvider);
  final participantDao = ref.watch(participantDaoProvider);
  
  return GroupRepository(
    conversationDao: conversationDao,
    participantDao: participantDao,
  );
});

// Add receiptDaoProvider to database_provider.dart if not already there
// final receiptDaoProvider = Provider<ReceiptDao>((ref) {
//   final db = ref.watch(appDbProvider);
//   return ReceiptDao(db);
// });
