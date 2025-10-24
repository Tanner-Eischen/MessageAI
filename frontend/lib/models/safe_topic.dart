import 'package:flutter/material.dart';

/// Model for safe topics
class SafeTopic {
  final String id;
  final String topicName;
  final List<String> keywords;
  final int messageCount;
  final int? avgResponseTime;
  final double? positiveToneRate;
  final bool isSafe;
  final int? lastDiscussed;

  SafeTopic({
    required this.id,
    required this.topicName,
    required this.keywords,
    required this.messageCount,
    this.avgResponseTime,
    this.positiveToneRate,
    this.isSafe = true,
    this.lastDiscussed,
  });

  factory SafeTopic.fromJson(Map<String, dynamic> json) {
    return SafeTopic(
      id: json['id'] as String,
      topicName: json['topic_name'] as String,
      keywords: (json['topic_keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      messageCount: json['message_count'] as int,
      avgResponseTime: json['avg_response_time'] as int?,
      positiveToneRate: (json['positive_tone_rate'] as num?)?.toDouble(),
      isSafe: json['is_safe'] as bool? ?? true,
      lastDiscussed: json['last_discussed'] as int?,
    );
  }

  Color getTopicColor() {
    if (positiveToneRate == null) return Colors.grey;
    if (positiveToneRate! >= 0.8) return Colors.green;
    if (positiveToneRate! >= 0.6) return Colors.blue;
    return Colors.orange;
  }

  String getEngagementLabel() {
    if (positiveToneRate == null) return 'Unknown';
    if (positiveToneRate! >= 0.8) return 'Great topic!';
    if (positiveToneRate! >= 0.6) return 'Good topic';
    return 'Neutral';
  }
}

