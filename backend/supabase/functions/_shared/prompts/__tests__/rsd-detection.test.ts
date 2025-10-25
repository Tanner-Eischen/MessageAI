import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { detectRSDTriggers, generateRSDPromptAddition } from '../rsd-detection.ts';

Deno.test('RSD Detection - "ok" message', () => {
  const triggers = detectRSDTriggers('ok');
  
  assertEquals(triggers.length, 2, 'Should detect 2 triggers: "ok" pattern + short_response');
  assertEquals(triggers[0].pattern, 'ok');
  assertEquals(triggers[0].severity, 'high');
  assertEquals(triggers[1].pattern, 'short_response');
});

Deno.test('RSD Detection - "fine" message', () => {
  const triggers = detectRSDTriggers('fine');
  
  assertEquals(triggers.length, 2, 'Should detect "fine" pattern + short_response');
  assertEquals(triggers[0].pattern, 'fine');
  assertEquals(triggers[0].severity, 'high');
});

Deno.test('RSD Detection - "k" message', () => {
  const triggers = detectRSDTriggers('k');
  
  assertEquals(triggers.length, 2, 'Should detect "k" pattern + short_response');
  assertEquals(triggers[0].pattern, 'k');
  assertEquals(triggers[0].severity, 'high');
});

Deno.test('RSD Detection - "we need to talk" message', () => {
  const triggers = detectRSDTriggers('we need to talk');
  
  assertEquals(triggers.length, 1, 'Should only detect "we need to talk" pattern, not short_response');
  assertEquals(triggers[0].pattern, 'we need to talk');
  assertEquals(triggers[0].severity, 'high');
});

Deno.test('RSD Detection - "sure" message', () => {
  const triggers = detectRSDTriggers('sure');
  
  assertEquals(triggers.length, 2, 'Should detect "sure" pattern + short_response');
  assertEquals(triggers[0].pattern, 'sure');
  assertEquals(triggers[0].severity, 'medium');
});

Deno.test('RSD Detection - message with warmth indicators', () => {
  const triggers1 = detectRSDTriggers('ok!');
  const triggers2 = detectRSDTriggers('ok 😊');
  const triggers3 = detectRSDTriggers('ok ❤️');
  
  assertEquals(triggers1.length, 1, 'Should only detect "ok", not short_response (has !)');
  assertEquals(triggers2.length, 1, 'Should only detect "ok", not short_response (has emoji)');
  assertEquals(triggers3.length, 1, 'Should only detect "ok", not short_response (has emoji)');
});

Deno.test('RSD Detection - normal message', () => {
  const triggers = detectRSDTriggers('Hey! How are you doing today?');
  
  assertEquals(triggers.length, 0, 'Should not detect any triggers in normal message');
});

Deno.test('RSD Detection - longer message with "ok" in it', () => {
  const triggers = detectRSDTriggers('That sounds ok to me, let me know when you want to meet');
  
  assertEquals(triggers.length, 1, 'Should detect "ok" pattern but not short_response');
  assertEquals(triggers[0].pattern, 'ok');
});

Deno.test('generateRSDPromptAddition - with triggers', () => {
  const triggers = detectRSDTriggers('ok');
  const prompt = generateRSDPromptAddition(triggers);
  
  assertEquals(prompt.includes('RSD ALERT'), true, 'Should include RSD ALERT header');
  assertEquals(prompt.includes('ok'), true, 'Should mention the "ok" pattern');
  assertEquals(prompt.includes('high severity'), true, 'Should mention severity');
});

Deno.test('generateRSDPromptAddition - no triggers', () => {
  const triggers = detectRSDTriggers('Hey there!');
  const prompt = generateRSDPromptAddition(triggers);
  
  assertEquals(prompt, '', 'Should return empty string when no triggers');
});

