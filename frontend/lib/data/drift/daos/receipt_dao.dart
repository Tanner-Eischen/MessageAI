import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'receipt_dao.g.dart';

@DriftAccessor(tables: [Receipts, Messages])
class ReceiptDao extends DatabaseAccessor<AppDb> with _$ReceiptDaoMixin {
  ReceiptDao(AppDb db) : super(db);

  /// Get all receipts for a message
  Future<List<Receipt>> getReceiptsByMessage(String messageId) async {
    return (select(receipts)
          ..where((r) => r.messageId.equals(messageId)))
        .get();
  }

  /// Get receipt by ID
  Future<Receipt?> getReceiptById(String id) async {
    return (select(receipts)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get receipt by message ID and user ID
  Future<Receipt?> getReceipt(String messageId, String userId) async {
    return (select(receipts)
          ..where((r) =>
              r.messageId.equals(messageId) & r.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Add receipt
  Future<void> addReceipt(Receipt receipt) async {
    await into(receipts).insert(receipt);
  }

  /// Batch add receipts
  Future<void> addReceipts(List<Receipt> recs) async {
    await batch((batch) {
      batch.insertAll(receipts, recs, mode: InsertMode.insertOrReplace);
    });
  }

  /// Update receipt status
  Future<void> updateReceiptStatus(String messageId, String userId, String status) async {
    await (update(receipts)
          ..where((r) =>
              r.messageId.equals(messageId) & r.userId.equals(userId)))
        .write(ReceiptsCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ));
  }

  /// Mark receipt as synced
  Future<void> markReceiptAsSynced(String id) async {
    await (update(receipts)..where((r) => r.id.equals(id)))
        .write(const ReceiptsCompanion(isSynced: Value(true)));
  }

  /// Mark multiple receipts as synced
  Future<void> markReceiptsAsSynced(List<String> ids) async {
    await batch((batch) {
      for (final id in ids) {
        batch.update(receipts, const ReceiptsCompanion(isSynced: Value(true)),
            where: (r) => r.id.equals(id));
      }
    });
  }

  /// Delete receipt
  Future<int> deleteReceipt(String id) async {
    return (delete(receipts)..where((r) => r.id.equals(id))).go();
  }

  /// Get unsynced receipts
  Future<List<Receipt>> getUnsyncedReceipts() async {
    return (select(receipts)..where((r) => r.isSynced.equals(false)))
        .get();
  }

  /// Get read count for a message
  Future<int> getReadCount(String messageId) async {
    final countResult = await (select(receipts)
          ..where((r) =>
              r.messageId.equals(messageId) & r.status.equals('read')))
        .get();
    return countResult.length;
  }

  /// Get delivered count for a message
  Future<int> getDeliveredCount(String messageId) async {
    final countResult = await (select(receipts)
          ..where((r) =>
              r.messageId.equals(messageId) & r.status.equals('delivered')))
        .get();
    return countResult.length;
  }

  /// Get all receipts for messages in conversation
  Future<List<Receipt>> getReceiptsByConversation(String conversationId) async {
    return (select(receipts).join([
      innerJoin(messages, messages.id.equalsExp(receipts.messageId)),
    ])
      ..where(messages.conversationId.equals(conversationId)))
        .map((row) => row.readTable(receipts))
        .get();
  }

  /// Check if message is read by all participants
  Future<bool> isReadByAll(String messageId, int expectedCount) async {
    final readCount = await getReadCount(messageId);
    return readCount >= expectedCount;
  }

  /// Get unsynced receipt count
  Future<int> getUnsyncedReceiptCount() async {
    final countResult = await (select(receipts)
          ..where((r) => r.isSynced.equals(false)))
        .get();
    return countResult.length;
  }
}
