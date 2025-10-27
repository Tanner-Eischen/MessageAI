/**
 * Feature 1: RSD Trigger Detection - Unit Tests
 * Tests RSD trigger detection and alternative interpretation generation
 */

import { describe, it, expect, beforeEach } from 'deno/testing/mod.ts';
import {
  detectRSDTriggers,
  generateRSDPromptAddition,
  type RSDTrigger,
} from '../supabase/functions/_shared/prompts/rsd-detection.ts';
import { F1_TEST_MESSAGES, F1_EXPECTED_INTERPRETATIONS } from '../test_fixtures.ts';

describe('Feature 1: RSD Detection Tests', () => {
  
  describe('RSD Trigger Detection', () => {
    
    it('detects "ok" as RSD trigger', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerOk.body);
      expect(triggers.length).toBeGreaterThan(0);
      expect(triggers.map(t => t.trigger_type)).toContain('short_response');
    });

    it('detects "k" as high-risk RSD trigger', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerK.body);
      expect(triggers.length).toBeGreaterThan(0);
      expect(triggers[0].risk_level).toBe('high');
    });

    it('detects "fine" with ambiguous potential', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerFine.body);
      expect(triggers.length).toBeGreaterThan(0);
      expect(triggers.some(t => t.trigger_type === 'single_word')).toBe(true);
    });

    it('detects dismissive emoji in "whatever 🙄"', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerWhatever.body);
      expect(triggers.length).toBeGreaterThan(0);
      expect(triggers.some(t => t.trigger_type === 'dismissive_tone')).toBe(true);
    });

    it('does not flag benign positive messages', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.benignYes.body);
      expect(triggers.length).toBe(0);
    });

    it('does not flag long detailed messages as RSD triggers', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.benignLongPositive.body);
      expect(triggers.length).toBe(0);
    });
  });

  describe('RSD Trigger Risk Levels', () => {
    
    it('categorizes risk levels correctly', () => {
      const triggersShort = detectRSDTriggers('k');
      const triggersMedium = detectRSDTriggers('ok');
      
      expect(triggersShort[0].risk_level).toBe('high');
      expect(triggersMedium.some(t => t.risk_level === 'medium')).toBe(true);
    });

    it('includes reassurance messages for high-risk triggers', () => {
      const triggers = detectRSDTriggers('k');
      expect(triggers[0].reassurance_message).toBeDefined();
      expect(triggers[0].reassurance_message).toContain('most likely');
    });
  });

  describe('RSD Prompt Generation', () => {
    
    it('generates prompt addition when triggers detected', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerOk.body);
      const promptAddition = generateRSDPromptAddition(triggers);
      
      expect(promptAddition).toBeDefined();
      expect(promptAddition.length).toBeGreaterThan(0);
      expect(promptAddition).toContain('RSD');
    });

    it('includes multiple interpretation guidance for RSD triggers', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerOk.body);
      const promptAddition = generateRSDPromptAddition(triggers);
      
      expect(promptAddition).toContain('interpretation');
      expect(promptAddition).toContain('likelihood');
    });

    it('emphasizes benign interpretation for RSD triggers', () => {
      const triggers = detectRSDTriggers(F1_TEST_MESSAGES.rsdTriggerOk.body);
      const promptAddition = generateRSDPromptAddition(triggers);
      
      expect(promptAddition.toLowerCase()).toContain('reassur');
    });
  });

  describe('Edge Cases', () => {
    
    it('handles empty string', () => {
      const triggers = detectRSDTriggers('');
      expect(triggers).toEqual([]);
    });

    it('handles messages with only emojis', () => {
      const triggers = detectRSDTriggers('🙄😔');
      expect(triggers.length).toBeGreaterThan(0);
    });

    it('handles mixed case appropriately', () => {
      const triggersLower = detectRSDTriggers('ok');
      const triggersUpper = detectRSDTriggers('OK');
      
      expect(triggersLower.length).toBeGreaterThan(0);
      expect(triggersUpper.length).toBeGreaterThan(0);
    });

    it('detects tone indicators like /j and /s', () => {
      const triggers = detectRSDTriggers('ok /j'); // with joking indicator
      // Tone indicators should reduce RSD concerns
      expect(triggers.length).toEqual(0); // Should be overridden
    });
  });

  describe('Integration with Alternative Interpretations', () => {
    
    it('provides reasoning for each interpretation', () => {
      const interpretations = F1_EXPECTED_INTERPRETATIONS.ok;
      
      interpretations.forEach(interp => {
        expect(interp.interpretation).toBeDefined();
        expect(interp.tone).toBeDefined();
        expect(interp.likelihood).toBeGreaterThanOrEqual(0);
        expect(interp.likelihood).toBeLessThanOrEqual(100);
        expect(interp.reasoning).toBeDefined();
      });
    });

    it('ranks interpretations by likelihood', () => {
      const interpretations = F1_EXPECTED_INTERPRETATIONS.ok;
      const sorted = [...interpretations].sort((a, b) => b.likelihood - a.likelihood);
      
      expect(interpretations[0].likelihood).toBeGreaterThanOrEqual(interpretations[1].likelihood);
    });

    it('includes benign interpretation as most likely', () => {
      const interpretations = F1_EXPECTED_INTERPRETATIONS.ok;
      const mostLikely = interpretations[0];
      
      expect(mostLikely.interpretation.toLowerCase()).toContain('acknowledgment');
      expect(mostLikely.likelihood).toBe(70);
    });
  });
});
