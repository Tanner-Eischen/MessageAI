import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { shouldGenerateAlternatives } from '../alternative-interpretations.ts';

Deno.test('shouldGenerateAlternatives - with RSD triggers', () => {
  const result = shouldGenerateAlternatives('ok', 1, 0.85);
  assertEquals(result, true, 'Should generate alternatives when RSD triggers detected');
});

Deno.test('shouldGenerateAlternatives - low confidence', () => {
  const result = shouldGenerateAlternatives('maybe...', 0, 0.5);
  assertEquals(result, true, 'Should generate alternatives when confidence < 0.7');
});

Deno.test('shouldGenerateAlternatives - short message', () => {
  const result = shouldGenerateAlternatives('ok', 0, 0.85);
  assertEquals(result, true, 'Should generate alternatives for short messages (≤3 words)');
});

Deno.test('shouldGenerateAlternatives - normal message, high confidence', () => {
  const result = shouldGenerateAlternatives('Hey! How are you doing today?', 0, 0.9);
  assertEquals(result, false, 'Should NOT generate alternatives for normal messages with high confidence');
});

Deno.test('shouldGenerateAlternatives - edge case 3 words', () => {
  const result = shouldGenerateAlternatives('I am good', 0, 0.85);
  assertEquals(result, true, 'Should generate alternatives for exactly 3 words');
});

Deno.test('shouldGenerateAlternatives - edge case 4 words', () => {
  const result = shouldGenerateAlternatives('I am doing good', 0, 0.85);
  assertEquals(result, false, 'Should NOT generate alternatives for 4 words with high confidence');
});

