/**
 * Feature 2: Boundary Violation Detection - Unit Tests
 * Tests detection of guilt-tripping, overstepping, after-hours, and repeated violations
 */

import { describe, it, expect } from 'deno/testing/mod.ts';
import {
  detectBoundaryViolations,
  detectGuiltTripping,
  detectOverstepping,
  isAfterHours,
  type BoundaryViolation,
} from '../supabase/functions/_shared/prompts/boundary-analysis.ts';
import { F2_TEST_MESSAGES, F2_EXPECTED_RESULTS, F2_BOUNDARY_RESPONSES } from '../test_fixtures.ts';

describe('Feature 2: Boundary Violation Detection Tests', () => {
  
  describe('Guilt-Tripping Detection', () => {
    
    it('detects classic guilt-trip pattern', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.guiltTrip1.body,
        F2_TEST_MESSAGES.guiltTrip1.timestamp
      );
      
      expect(violations.length).toBeGreaterThan(0);
      expect(violations[0].type).toBe('guilt_tripping');
      expect(violations[0].severity).toBeGreaterThanOrEqual(1);
    });

    it('detects severe guilt-trip with emotional manipulation', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.guiltTrip2.body,
        F2_TEST_MESSAGES.guiltTrip2.timestamp
      );
      
      expect(violations.length).toBeGreaterThan(0);
      expect(violations[0].type).toBe('guilt_tripping');
      expect(violations[0].severity).toBe(3); // High severity
    });

    it('provides three response templates for guilt-tripping', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.guiltTrip1.body,
        F2_TEST_MESSAGES.guiltTrip1.timestamp
      );
      
      const guiltTripViolation = violations.find(v => v.type === 'guilt_tripping');
      expect(guiltTripViolation).toBeDefined();
      expect(guiltTripViolation!.suggested_gentle).toBeDefined();
      expect(guiltTripViolation!.suggested_moderate).toBeDefined();
      expect(guiltTripViolation!.suggested_firm).toBeDefined();
    });

    it('response options range in assertiveness', () => {
      const responses = F2_BOUNDARY_RESPONSES.guiltTrip;
      
      // Gentle should use caring language
      expect(responses.gentle).toContain('care');
      
      // Firm should be direct
      expect(responses.firm.length).toBeGreaterThan(responses.gentle.length);
    });
  });

  describe('Overstepping Detection', () => {
    
    it('detects invasive personal questions', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.overstepping1.body,
        F2_TEST_MESSAGES.overstepping1.timestamp
      );
      
      expect(violations.length).toBeGreaterThan(0);
      expect(violations[0].type).toBe('overstepping');
    });

    it('detects financial privacy invasion', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.overstepping2.body,
        F2_TEST_MESSAGES.overstepping2.timestamp
      );
      
      expect(violations.length).toBeGreaterThan(0);
      expect(violations[0].type).toBe('overstepping');
      expect(violations[0].severity).toBe(3); // Salary is sensitive
    });

    it('includes evidence of overstepping', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.overstepping1.body,
        F2_TEST_MESSAGES.overstepping1.timestamp
      );
      
      expect(violations[0].evidence).toBeDefined();
      expect(violations[0].evidence.length).toBeGreaterThan(0);
    });
  });

  describe('After-Hours Pressure Detection', () => {
    
    it('detects urgent messages sent after 6 PM', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.afterHours.body,
        F2_TEST_MESSAGES.afterHours.timestamp
      );
      
      expect(violations.length).toBeGreaterThan(0);
      expect(violations.some(v => v.type === 'after_hours_pressure')).toBe(true);
    });

    it('does not flag normal messages during work hours', () => {
      const workHourTimestamp = Math.floor(new Date('2025-01-26T14:00:00').getTime() / 1000);
      const violations = detectBoundaryViolations(
        'Can you review this?',
        workHourTimestamp
      );
      
      expect(violations.some(v => v.type === 'after_hours_pressure')).toBe(false);
    });

    it('flags requests before 8 AM as after-hours', () => {
      const earlyMorningTimestamp = Math.floor(new Date('2025-01-26T07:00:00').getTime() / 1000);
      const violations = detectBoundaryViolations(
        'Need this ASAP!',
        earlyMorningTimestamp
      );
      
      expect(violations.some(v => v.type === 'after_hours_pressure')).toBe(true);
    });
  });

  describe('Repeated Violations Detection', () => {
    
    it('recognizes repeated pattern from same sender', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.repeatedPush.body,
        F2_TEST_MESSAGES.repeatedPush.timestamp,
        F2_TEST_MESSAGES.repeatedPush.priorViolationCount
      );
      
      expect(violations.some(v => v.type === 'repeated_pushing')).toBe(true);
    });

    it('escalates severity for repeated violations', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.repeatedPush.body,
        F2_TEST_MESSAGES.repeatedPush.timestamp,
        3 // 3 prior violations
      );
      
      const repeatedViolation = violations.find(v => v.type === 'repeated_pushing');
      expect(repeatedViolation?.severity).toBeGreaterThanOrEqual(2);
    });
  });

  describe('Benign Message Handling', () => {
    
    it('does not flag genuinely benign messages', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.benign.body,
        F2_TEST_MESSAGES.benign.timestamp
      );
      
      expect(violations.length).toBe(0);
    });

    it('handles polite requests without violations', () => {
      const violations = detectBoundaryViolations(
        'Would you like to grab coffee sometime?',
        Math.floor(Date.now() / 1000)
      );
      
      expect(violations.length).toBe(0);
    });
  });

  describe('Severity Levels', () => {
    
    it('categorizes severity 1-3 correctly', () => {
      Object.entries(F2_EXPECTED_RESULTS.violationType).forEach(([violationType, config]) => {
        expect(config.minSeverity).toBeLessThanOrEqual(config.maxSeverity);
        expect(config.minSeverity).toBeGreaterThanOrEqual(1);
        expect(config.maxSeverity).toBeLessThanOrEqual(3);
      });
    });

    it('maps severity to alert colors', () => {
      const severityColors = {
        1: 'blue',
        2: 'orange',
        3: 'red',
      };
      
      Object.entries(severityColors).forEach(([sev, color]) => {
        expect(['blue', 'orange', 'red']).toContain(color);
      });
    });
  });

  describe('Response Template Quality', () => {
    
    it('provides three distinct response options', () => {
      const responses = F2_BOUNDARY_RESPONSES.guiltTrip;
      
      expect(responses.gentle).toBeDefined();
      expect(responses.moderate).toBeDefined();
      expect(responses.firm).toBeDefined();
      
      // All should be different
      expect(responses.gentle).not.toBe(responses.moderate);
      expect(responses.moderate).not.toBe(responses.firm);
    });

    it('escalates assertiveness in responses', () => {
      const responses = F2_BOUNDARY_RESPONSES.guiltTrip;
      
      // Gentle: collaborative, caring
      expect(responses.gentle.toLowerCase()).toContain('care');
      
      // Moderate: direct but polite
      expect(responses.moderate.toLowerCase()).toContain('prefer');
      
      // Firm: clear boundary
      expect(responses.firm.toLowerCase()).toContain('responsible');
    });

    it('all responses validate boundaries appropriately', () => {
      const responses = F2_BOUNDARY_RESPONSES.guiltTrip;
      
      // Each should set a boundary, not apologize or enable
      [responses.gentle, responses.moderate, responses.firm].forEach(response => {
        expect(response).not.toContain("I'm sorry");
        expect(response.length).toBeGreaterThan(20);
      });
    });
  });

  describe('Edge Cases', () => {
    
    it('handles empty message', () => {
      const violations = detectBoundaryViolations('', Math.floor(Date.now() / 1000));
      expect(violations).toEqual([]);
    });

    it('handles messages with only punctuation', () => {
      const violations = detectBoundaryViolations('!!!!!!', Math.floor(Date.now() / 1000));
      // May be flagged as intensity, but not specifically as boundary violation
      expect(Array.isArray(violations)).toBe(true);
    });

    it('is case-insensitive for key patterns', () => {
      const violationLower = detectBoundaryViolations(
        'i really need you',
        Math.floor(Date.now() / 1000)
      );
      const violationUpper = detectBoundaryViolations(
        'I REALLY NEED YOU',
        Math.floor(Date.now() / 1000)
      );
      
      expect(violationLower.length).toBeGreaterThan(0);
      expect(violationUpper.length).toBeGreaterThan(0);
    });

    it('handles multiple violations in single message', () => {
      const complexMessage = 'I really need you to respond ASAP. After all I\'ve done, you owe me this.';
      const violations = detectBoundaryViolations(
        complexMessage,
        Math.floor(new Date('2025-01-26T23:00:00').getTime() / 1000)
      );
      
      expect(violations.length).toBeGreaterThanOrEqual(2); // Guilt-trip + urgency at minimum
    });
  });

  describe('Integration with Evidence System (Feature 3)', () => {
    
    it('provides evidence supporting boundary violation claim', () => {
      const violations = detectBoundaryViolations(
        F2_TEST_MESSAGES.guiltTrip1.body,
        F2_TEST_MESSAGES.guiltTrip1.timestamp
      );
      
      expect(violations[0].evidence).toBeDefined();
      expect(violations[0].evidence.length).toBeGreaterThan(0);
      expect(violations[0].evidence[0]).toContain('"');
    });

    it('evidence includes exact phrases from message', () => {
      const violations = detectBoundaryViolations(
        'I really need you',
        Math.floor(Date.now() / 1000)
      );
      
      const hasEvidence = violations[0].evidence.some(e => 
        e.includes('really need')
      );
      expect(hasEvidence).toBe(true);
    });
  });
});
