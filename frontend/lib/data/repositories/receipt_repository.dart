import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/receipt_dao.dart';
import 'package:messageai/data/drift/daos/pending_outbox_dao.dart';
import 'package:messageai/gen/api/clients/receipts_api.dart';
import 'package:messageai/gen/api/models/receipt_payload.dart';

/// Repository for receipt operations combining API and local database
class ReceiptRepository {
  final ReceiptsApi _receiptsApi;
  final ReceiptDao _receiptDao;
  final PendingOutboxDao _outboxDao;

  ReceiptRepository({
    required ReceiptsApi receiptsApi,
    required ReceiptDao receiptDao,
    required PendingOutboxDao outboxDao,
  })  : _receiptsApi = receiptsApi,
        _receiptDao = receiptDao,
        _outboxDao = outboxDao;

  /// Acknowledge message receipts (optimistic)
  Future<void> acknowledgeReceipts({
    required List<String> messageIds,
    required String status, // 'delivered' or 'read'
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Save receipts locally first
    final receipts = messageIds.map((msgId) {
      return Receipt(
        id: '${msgId}_${status}_$now',
        messageId: msgId,
        userId: '', // Would be current user ID
        status: status,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );
    }).toList();
    
    await _receiptDao.addReceipts(receipts);
    
    // Queue for sync
    await _outboxDao.addPendingOperation(
      id: 'ack_${status}_$now',
      operation: 'ack_receipt',
      payload: ReceiptPayload(
        messageIds: messageIds,
        status: status == 'delivered' ? ReceiptStatus.delivered : ReceiptStatus.read,
      ).toJson().toString(),
      conversationId: null,
    );
  }

  /// Get receipts for a message
  Future<List<Receipt>> getMessageReceipts(String messageId) async {
    return _receiptDao.getReceiptsByMessage(messageId);
  }

  /// Get read count for a message
  Future<int> getReadCount(String messageId) async {
    return _receiptDao.getReadCount(messageId);
  }

  /// Get delivered count for a message
  Future<int> getDeliveredCount(String messageId) async {
    return _receiptDao.getDeliveredCount(messageId);
  }

  /// Check if message is read by all participants
  Future<bool> isReadByAll(String messageId, int participantCount) async {
    return _receiptDao.isReadByAll(messageId, participantCount);
  }

  /// Sync unsynced receipts to server
  Future<void> syncUnsyncedReceipts() async {
    final unsyncedReceipts = await _receiptDao.getUnsyncedReceipts();
    
    if (unsyncedReceipts.isEmpty) return;
    
    try {
      // Group by status
      final deliveredIds = unsyncedReceipts
          .where((r) => r.status == 'delivered')
          .map((r) => r.messageId)
          .toList();
      
      final readIds = unsyncedReceipts
          .where((r) => r.status == 'read')
          .map((r) => r.messageId)
          .toList();
      
      // Send to server
      if (deliveredIds.isNotEmpty) {
        final payload = ReceiptPayload(
          messageIds: deliveredIds,
          status: ReceiptStatus.delivered,
        );
        await _receiptsApi.ack(payload);
      }
      
      if (readIds.isNotEmpty) {
        final payload = ReceiptPayload(
          messageIds: readIds,
          status: ReceiptStatus.read,
        );
        await _receiptsApi.ack(payload);
      }
      
      // Mark as synced
      final allIds = unsyncedReceipts.map((r) => r.id).toList();
      await _receiptDao.markReceiptsAsSynced(allIds);
    } catch (e) {
      print('Error syncing receipts: $e');
    }
  }

  /// Insert receipts from server
  Future<void> insertServerReceipts(List<Receipt> receipts) async {
    await _receiptDao.addReceipts(receipts);
  }

  /// Get unsynced receipt count (for UI)
  Future<int> getUnsyncedReceiptCount() async {
    return _receiptDao.getUnsyncedReceiptCount();
  }
}

extension on ReceiptPayload {
  Map<String, dynamic> toJson() => {
    'message_ids': messageIds,
    'status': status.toValue(),
  };
}
