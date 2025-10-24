import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('RSDTrigger Model Tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'pattern': 'ok',
        'severity': 'high',
        'explanation': 'Single-word responses can trigger RSD',
        'reassurance': 'This is likely just a quick acknowledgment',
      };

      final trigger = RSDTrigger.fromJson(json);

      expect(trigger.pattern, 'ok');
      expect(trigger.severity, 'high');
      expect(trigger.explanation, 'Single-word responses can trigger RSD');
      expect(trigger.reassurance, 'This is likely just a quick acknowledgment');
    });

    test('toJson serializes correctly', () {
      const trigger = RSDTrigger(
        pattern: 'fine',
        severity: 'high',
        explanation: 'Fine can feel passive-aggressive',
        reassurance: 'They might genuinely mean it',
      );

      final json = trigger.toJson();

      expect(json['pattern'], 'fine');
      expect(json['severity'], 'high');
      expect(json['explanation'], 'Fine can feel passive-aggressive');
      expect(json['reassurance'], 'They might genuinely mean it');
    });

    test('isHighSeverity returns true for high severity', () {
      const trigger = RSDTrigger(
        pattern: 'ok',
        severity: 'high',
        explanation: 'test',
        reassurance: 'test',
      );

      expect(trigger.isHighSeverity, true);
      expect(trigger.isMediumSeverity, false);
      expect(trigger.isLowSeverity, false);
    });

    test('isMediumSeverity returns true for medium severity', () {
      const trigger = RSDTrigger(
        pattern: 'sure',
        severity: 'medium',
        explanation: 'test',
        reassurance: 'test',
      );

      expect(trigger.isHighSeverity, false);
      expect(trigger.isMediumSeverity, true);
      expect(trigger.isLowSeverity, false);
    });

    test('isLowSeverity returns true for low severity', () {
      const trigger = RSDTrigger(
        pattern: 'no worries',
        severity: 'low',
        explanation: 'test',
        reassurance: 'test',
      );

      expect(trigger.isHighSeverity, false);
      expect(trigger.isMediumSeverity, false);
      expect(trigger.isLowSeverity, true);
    });
  });
}

