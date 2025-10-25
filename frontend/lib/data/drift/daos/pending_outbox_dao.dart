import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'pending_outbox_dao.g.dart';

@DriftAccessor(tables: [PendingOutbox])
class PendingOutboxDao extends DatabaseAccessor<AppDb> with _$PendingOutboxDaoMixin {
  PendingOutboxDao(AppDb db) : super(db);

  /// Get all pending operations
  Future<List<PendingOutboxData>> getAllPendingOperations() async {
    return (select(pendingOutbox)
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]))
        .get();
  }

  /// Get pending operations for a specific conversation
  Future<List<PendingOutboxData>> getPendingOperationsByConversation(String conversationId) async {
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
    await into(pendingOutbox).insert(PendingOutboxCompanion(
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
  Future<void> updateRetryInfo(String id, int retryCount, String? lastError) async {
    await (update(pendingOutbox)..where((p) => p.id.equals(id)))
        .write(PendingOutboxCompanion(
          retryCount: Value(retryCount),
          lastError: Value(lastError),
        ));
  }

  /// Get retryable operations (with retry count < max retries)
  Future<List<PendingOutboxData>> getRetryableOperations({int maxRetries = 3}) async {
    return (select(pendingOutbox)
          ..where((p) => p.retryCount.isSmallerThanValue(maxRetries)))
        .get();
  }

  /// Get oldest pending operation
  Future<PendingOutboxData?> getOldestPendingOperation() async {
    return (select(pendingOutbox)
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get pending operations by type
  Future<List<PendingOutboxData>> getPendingOperationsByType(String operationType) async {
    return (select(pendingOutbox)
          ..where((p) => p.operation.equals(operationType)))
        .get();
  }

  /// Clean up old pending operations (older than cutoffTime)
  Future<int> cleanupOldOperations(int cutoffTime) async {
    return (delete(pendingOutbox)..where((p) => p.createdAt.isSmallerThanValue(cutoffTime))).go();
  }

  /// Get pending operations count
  Future<int> getPendingOperationCount() async {
    final result = await select(pendingOutbox).get();
    return result.length;
  }

  /// Check if there are any pending operations
  Future<bool> hasPendingOperations() async {
    final count = await getPendingOperationCount();
    return count > 0;
  }
}
