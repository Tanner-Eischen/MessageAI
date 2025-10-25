import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/relationship_profile.dart';

void main() {
  group('RelationshipProfile', () {
    test('fromJson creates RelationshipProfile correctly', () {
      final json = {
        'profile_id': 'profile-123',
        'user_id': 'user-456',
        'conversation_id': 'conv-789',
        'participant_name': 'John Doe',
        'participant_user_id': 'user-999',
        'relationship_type': 'colleague',
        'relationship_notes': 'Works in marketing',
        'conversation_summary': 'We discuss project updates',
        'safe_topics': ['work', 'sports', 'weather'],
        'topics_to_avoid': ['politics', 'religion'],
        'communication_style': 'Direct and professional',
        'typical_response_time': 3600, // 1 hour
        'total_messages': 150,
        'first_message_at': 1640000000,
        'last_message_at': 1650000000,
      };

      final profile = RelationshipProfile.fromJson(json);

      expect(profile.id, 'profile-123');
      expect(profile.userId, 'user-456');
      expect(profile.conversationId, 'conv-789');
      expect(profile.participantName, 'John Doe');
      expect(profile.participantUserId, 'user-999');
      expect(profile.relationshipType, 'colleague');
      expect(profile.relationshipNotes, 'Works in marketing');
      expect(profile.conversationSummary, 'We discuss project updates');
      expect(profile.safeTopics, ['work', 'sports', 'weather']);
      expect(profile.topicsToAvoid, ['politics', 'religion']);
      expect(profile.communicationStyle, 'Direct and professional');
      expect(profile.typicalResponseTime, 3600);
      expect(profile.totalMessages, 150);
      expect(profile.firstMessageAt, 1640000000);
      expect(profile.lastMessageAt, 1650000000);
    });

    test('fromJson handles id field if profile_id is missing', () {
      final json = {
        'id': 'profile-123',
        'user_id': 'user-456',
        'conversation_id': 'conv-789',
        'participant_name': 'Jane Doe',
      };

      final profile = RelationshipProfile.fromJson(json);

      expect(profile.id, 'profile-123');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'profile_id': 'profile-123',
        'user_id': 'user-456',
        'conversation_id': 'conv-789',
        'participant_name': 'John Doe',
      };

      final profile = RelationshipProfile.fromJson(json);

      expect(profile.participantUserId, null);
      expect(profile.relationshipType, null);
      expect(profile.safeTopics, []);
      expect(profile.topicsToAvoid, []);
      expect(profile.totalMessages, 0);
    });

    test('getRelationshipEmoji returns correct emoji for each type', () {
      final testCases = {
        'boss': '👔',
        'colleague': '🤝',
        'friend': '😊',
        'family': '👨‍👩‍👧‍👦',
        'client': '💼',
        'unknown': '👤',
      };

      testCases.forEach((type, expectedEmoji) {
        final profile = RelationshipProfile(
          id: 'test',
          userId: 'user',
          conversationId: 'conv',
          participantName: 'Test',
          relationshipType: type == 'unknown' ? null : type,
        );

        expect(profile.getRelationshipEmoji(), expectedEmoji);
      });
    });

    test('getRelationshipEmoji is case-insensitive', () {
      final profile = RelationshipProfile(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        participantName: 'Test',
        relationshipType: 'BOSS',
      );

      expect(profile.getRelationshipEmoji(), '👔');
    });

    test('formatResponseTime returns "Unknown" for null', () {
      final profile = RelationshipProfile(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        participantName: 'Test',
      );

      expect(profile.formatResponseTime(), 'Unknown');
    });

    test('formatResponseTime returns minutes for < 1 hour', () {
      final profile = RelationshipProfile(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        participantName: 'Test',
        typicalResponseTime: 1800, // 30 minutes
      );

      expect(profile.formatResponseTime(), '30 min');
    });

    test('formatResponseTime returns hours for < 1 day', () {
      final profile = RelationshipProfile(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        participantName: 'Test',
        typicalResponseTime: 7200, // 2 hours
      );

      expect(profile.formatResponseTime(), '2 hr');
    });

    test('formatResponseTime returns days for >= 1 day', () {
      final profile = RelationshipProfile(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        participantName: 'Test',
        typicalResponseTime: 172800, // 2 days
      );

      expect(profile.formatResponseTime(), '2 days');
    });
  });
}

