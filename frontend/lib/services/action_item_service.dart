import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/action_item_extended.dart';

class ActionItemService {
  static final ActionItemService _instance = ActionItemService._internal();

  factory ActionItemService() {
    return _instance;
  }

  ActionItemService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all upcoming action items for the current user (due within N days)
  Future<List<ActionItemWithStatus>> getUpcomingItems({int daysAhead = 7}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc(
        'get_upcoming_action_items',
        params: {
          'p_user_id': userId,
          'p_days_ahead': daysAhead,
        },
      ) as List;

      return response
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting upcoming items: $e');
      return [];
    }
  }

  /// Get action items timeline for a specific conversation
  Future<List<ActionItemWithStatus>> getConversationTimeline(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in');
        return [];
      }

      print('🔍 Fetching action items for conversation: $conversationId');

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);

      print('📊 Found ${(response as List).length} action items');

      return (response)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting conversation timeline: $e');
      return [];
    }
  }

  /// Update action item status
  Future<bool> updateItemStatus(
    String itemId,
    String newStatus, {
    String? reason,
  }) async {
    try {
      final response = await _supabase.rpc(
        'update_action_item_status',
        params: {
          'p_action_item_id': itemId,
          'p_new_status': newStatus,
          if (reason != null) 'p_reason': reason,
        },
      ) as bool;

      if (response) {
        print('✅ Action item status updated to $newStatus');
        // Trigger streak update
        await _updateStreak();
      }
      return response;
    } catch (e) {
      print('❌ Error updating item status: $e');
      return false;
    }
  }

  /// Mark an action item as completed
  Future<bool> markCompleted(String itemId) async {
    return updateItemStatus(itemId, 'completed', reason: 'User marked as complete');
  }

  /// Reschedule an action item
  Future<bool> rescheduleItem(String itemId, int newDeadline) async {
    try {
      await _supabase
          .from('action_items')
          .update({
            'extracted_deadline': newDeadline,
            'status': 'rescheduled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);

      print('✅ Action item rescheduled');
      return true;
    } catch (e) {
      print('❌ Error rescheduling item: $e');
      return false;
    }
  }

  /// Cancel an action item
  Future<bool> cancelItem(String itemId, {String? reason}) async {
    return updateItemStatus(itemId, 'cancelled', reason: reason);
  }

  /// Get current user's commitment streak
  /// NOTE: commitment_streaks table doesn't exist yet, returning null
  Future<CommitmentStreak?> getStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      // TODO: Implement when commitment_streaks table is created
      print('⏭️  Streak feature not yet available');
      return null;
    } catch (e) {
      print('⚠️ Error getting streak: $e');
      return null;
    }
  }

  /// Update streak (called after status changes)
  /// NOTE: commitment_streaks table doesn't exist yet, skipping
  Future<bool> _updateStreak() async {
    try {
      // TODO: Implement when commitment_streaks table is created
      print('⏭️  Streak update skipped (feature not yet available)');
      return true;  // Return true so it doesn't error downstream
    } catch (e) {
      print('⚠️ Error updating streak: $e');
      return false;
    }
  }

  /// Get all pending action items
  Future<List<ActionItemWithStatus>> getPendingItems() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .in_('status', ['pending', 'in_progress'])
          .order('extracted_deadline');

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting pending items: $e');
      return [];
    }
  }

  /// Get completed action items
  Future<List<ActionItemWithStatus>> getCompletedItems({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('status_updated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting completed items: $e');
      return [];
    }
  }

  /// Search action items by commitment text
  Future<List<ActionItemWithStatus>> searchItems(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .textSearch('search_vector', query);

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error searching items: $e');
      return [];
    }
  }

  /// Get action items by type
  Future<List<ActionItemWithStatus>> getItemsByType(String actionType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .eq('action_type', actionType)
          .order('extracted_deadline');

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting items by type: $e');
      return [];
    }
  }

  /// Get items that are overdue
  Future<List<ActionItemWithStatus>> getOverdueItems() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .lt('extracted_deadline', now)
          .in_('status', ['pending', 'in_progress'])
          .order('extracted_deadline');

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting overdue items: $e');
      return [];
    }
  }

  /// Get statistics about user's commitments
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final upcoming = await getUpcomingItems(daysAhead: 7);
      final pending = await getPendingItems();
      final completed = await getCompletedItems(limit: 100);
      final overdue = await getOverdueItems();
      final streak = await getStreak();

      return {
        'upcomingCount': upcoming.length,
        'pendingCount': pending.length,
        'completedCount': completed.length,
        'overdueCount': overdue.length,
        'completionRate': streak?.completionRate ?? 0.0,
        'currentStreak': streak?.currentStreakCount ?? 0,
        'bestStreak': streak?.bestStreakCount ?? 0,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }

  /// Extract commitments from a message using AI
  Future<CommitmentExtractionResult?> extractCommitments({
    required String messageId,
    required String messageBody,
    required String conversationId,
    List<String>? conversationContext,
  }) async {
    try {
      print('🔍 Extracting commitments from message: $messageId');
      
      print('📤 Calling extract-commitments function...');
      print('   Message: ${messageBody.substring(0, messageBody.length.clamp(0, 100))}');
      
      final response = await _supabase.functions.invoke(
        'extract-commitments',
        body: {
          'message_id': messageId,
          'message_body': messageBody,
          'conversation_id': conversationId,
          if (conversationContext != null)
            'conversation_context': conversationContext,
        },
      );

      print('📥 Response status: ${response.status}');
      
      if (response.status != 200) {
        print('❌ Commitment extraction failed: ${response.status}');
        print('   Response data: ${response.data}');
        return null;
      }

      final data = response.data as Map<String, dynamic>?;
      print('📊 Response data: $data');
      
      if (data == null || data['success'] != true) {
        print('❌ Commitment extraction unsuccessful');
        print('   Error: ${data?['error']}');
        return null;
      }

      final commitmentsFound = data['commitments_found'] as int? ?? 0;
      final actionItemsCreated = data['action_items_created'] as int? ?? 0;
      final actionItems = (data['action_items'] as List?)
          ?.map((item) => ActionItemSummary.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];

      print('✅ Extracted $commitmentsFound commitments, created $actionItemsCreated action items');

      return CommitmentExtractionResult(
        commitmentsFound: commitmentsFound,
        actionItemsCreated: actionItemsCreated,
        actionItems: actionItems,
      );
    } catch (e) {
      print('❌ Error extracting commitments: $e');
      return null;
    }
  }

  /// Get action items for a specific message
  Future<List<ActionItemWithStatus>> getMessageActionItems(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('action_items')
          .select()
          .eq('user_id', userId)
          .eq('message_id', messageId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ActionItemWithStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting message action items: $e');
      return [];
    }
  }
}

/// Result from commitment extraction
class CommitmentExtractionResult {
  final int commitmentsFound;
  final int actionItemsCreated;
  final List<ActionItemSummary> actionItems;

  CommitmentExtractionResult({
    required this.commitmentsFound,
    required this.actionItemsCreated,
    required this.actionItems,
  });
}

/// Summary of created action item
class ActionItemSummary {
  final String id;
  final String commitment;
  final String actionType;
  final DateTime? deadline;

  ActionItemSummary({
    required this.id,
    required this.commitment,
    required this.actionType,
    this.deadline,
  });

  factory ActionItemSummary.fromJson(Map<String, dynamic> json) {
    return ActionItemSummary(
      id: json['id'] as String,
      commitment: json['commitment'] as String,
      actionType: json['actionType'] as String,
      deadline: json['deadline'] != null 
        ? DateTime.parse(json['deadline'] as String)
        : null,
    );
  }
}
