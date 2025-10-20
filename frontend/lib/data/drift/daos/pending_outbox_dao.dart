import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'pending_outbox_dao.g.dart';

@DriftAccessor(tables: [PendingOutbox])
class PendingOutboxDao extends DatabaseAccessor<AppDb> {
  PendingOutboxDao(AppDb db) : super(db);

  /// Get all pending operations
  Future<List<PendingOutboxItem>> getAllPendingOperations() async {
    return (select(pendingOutbox)
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();
  }

  /// Get pending operations for a specific conversation
  Future<List<PendingOutboxItem>> getPendingOperationsByConversation(String conversationId) async {
    return (select(pendingOutbox)
          ..where((p) => p.conversationId.equals(conversationId))
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();
  }

  /// Add operation to pending outbox
  Future<void> addPendingOperation({
    required String id,
    required String operation,
    required String payload,
    required String? conversationId,
  }) async {
    await into(pendingOutbox).insert(PendingOutboxItemsCompanion(
      id: Value(id),
      operation: Value(operation),
      payload: Value(payload),
      conversationId: Value(conversationId),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      retryCount: const Value(0),
    ));
  }

  /// Remove operation from pending outbox (after successful sync)
  Future<int> removePendingOperation(String id) async {
    return (delete(pendingOutbox)..where((p) => p.id.equals(id))).go();
  }

  /// Batch remove multiple operations
  Future<int> removePendingOperations(List<String> ids) async {
    return (delete(pendingOutbox)..where((p) => p.id.isIn(ids))).go();
  }

  /// Update retry count and last error
  Future<void> updateRetry(String id, String? errorMessage) async {
    final item = await (select(pendingOutbox)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();

    if (item != null) {
      await (update(pendingOutbox)..where((p) => p.id.equals(id)))
          .write(PendingOutboxItemsCompanion(
            retryCount: Value(item.retryCount + 1),
            lastError: Value(errorMessage),
          ));
    }
  }

  /// Get pending operations with retry count less than max
  Future<List<PendingOutboxItem>> getRetryableOperations({int maxRetries = 3}) async {
    return (select(pendingOutbox)
          ..where((p) => p.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();
  }

  /// Get oldest pending operation (for processing)
  Future<PendingOutboxItem?> getOldestPendingOperation() async {
    return (select(pendingOutbox)
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get pending operations by type
  Future<List<PendingOutboxItem>> getPendingOperationsByType(String operationType) async {
    return (select(pendingOutbox)
          ..where((p) => p.operation.equals(operationType))
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();
  }

  /// Count pending operations
  Future<int> getPendingOperationCount() async {
    final result = await (select(pendingOutbox)
          ..addColumns([countAll()]))
        .map((row) => row.read<int>(countAll()))
        .getSingle();
    return result;
  }

  /// Clear all pending operations (use with caution)
  Future<int> clearAllPendingOperations() async {
    return delete(pendingOutbox).go();
  }

  /// Clear operations older than a certain time
  Future<int> clearOldOperations(int secondsAgo) async {
    final cutoffTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - secondsAgo;
    return (delete(pendingOutbox)..where((p) => p.createdAt.isSmallerThan(cutoffTime)))
        .go();
  }

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final count = await getPendingOperationCount();
    return count > 0;
  }
}
