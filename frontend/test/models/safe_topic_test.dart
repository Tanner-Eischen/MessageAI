import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/safe_topic.dart';

void main() {
  group('SafeTopic', () {
    test('fromJson creates SafeTopic correctly', () {
      final json = {
        'id': 'topic-123',
        'topic_name': 'Project Updates',
        'topic_keywords': ['deadline', 'status', 'progress'],
        'message_count': 25,
        'avg_response_time': 1800,
        'positive_tone_rate': 0.85,
        'is_safe': true,
        'last_discussed': 1640000000,
      };

      final topic = SafeTopic.fromJson(json);

      expect(topic.id, 'topic-123');
      expect(topic.topicName, 'Project Updates');
      expect(topic.keywords, ['deadline', 'status', 'progress']);
      expect(topic.messageCount, 25);
      expect(topic.avgResponseTime, 1800);
      expect(topic.positiveToneRate, 0.85);
      expect(topic.isSafe, true);
      expect(topic.lastDiscussed, 1640000000);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'topic-123',
        'topic_name': 'General',
        'message_count': 10,
      };

      final topic = SafeTopic.fromJson(json);

      expect(topic.keywords, []);
      expect(topic.avgResponseTime, null);
      expect(topic.positiveToneRate, null);
      expect(topic.isSafe, true);
      expect(topic.lastDiscussed, null);
    });

    test('getTopicColor returns green for high positive rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.9,
      );

      expect(topic.getTopicColor(), Colors.green);
    });

    test('getTopicColor returns blue for medium positive rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.7,
      );

      expect(topic.getTopicColor(), Colors.blue);
    });

    test('getTopicColor returns orange for low positive rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.5,
      );

      expect(topic.getTopicColor(), Colors.orange);
    });

    test('getTopicColor returns grey for null positive rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
      );

      expect(topic.getTopicColor(), Colors.grey);
    });

    test('getEngagementLabel returns "Great topic!" for high rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.85,
      );

      expect(topic.getEngagementLabel(), 'Great topic!');
    });

    test('getEngagementLabel returns "Good topic" for medium rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.65,
      );

      expect(topic.getEngagementLabel(), 'Good topic');
    });

    test('getEngagementLabel returns "Neutral" for low rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
        positiveToneRate: 0.5,
      );

      expect(topic.getEngagementLabel(), 'Neutral');
    });

    test('getEngagementLabel returns "Unknown" for null rate', () {
      final topic = SafeTopic(
        id: 'test',
        topicName: 'Test',
        keywords: [],
        messageCount: 10,
      );

      expect(topic.getEngagementLabel(), 'Unknown');
    });

    test('isSafe defaults to true', () {
      final json = {
        'id': 'topic-123',
        'topic_name': 'Test',
        'message_count': 10,
      };

      final topic = SafeTopic.fromJson(json);

      expect(topic.isSafe, true);
    });
  });
}

