import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { formatEvidence, type Evidence } from '../evidence-extractor.ts';

Deno.test('formatEvidence - with evidence', () => {
  const evidence: Evidence[] = [
    {
      type: 'keyword',
      quote: 'ASAP',
      supports: 'urgency',
      reasoning: 'Explicit urgency marker'
    },
    {
      type: 'punctuation',
      quote: '!!!',
      supports: 'high intensity',
      reasoning: 'Multiple exclamation marks show strong emotion'
    }
  ];
  
  const formatted = formatEvidence(evidence);
  
  assertEquals(formatted.includes('ASAP'), true, 'Should include the quote');
  assertEquals(formatted.includes('keyword'), true, 'Should include the type');
  assertEquals(formatted.includes('urgency'), true, 'Should include what it supports');
});

Deno.test('formatEvidence - empty evidence', () => {
  const evidence: Evidence[] = [];
  const formatted = formatEvidence(evidence);
  
  assertEquals(formatted, 'No specific evidence found in message');
});

Deno.test('formatEvidence - multiple evidence types', () => {
  const evidence: Evidence[] = [
    {
      type: 'emoji',
      quote: '😊',
      supports: 'friendly tone',
      reasoning: 'Smiling emoji indicates friendliness'
    },
    {
      type: 'length',
      quote: 'very short',
      supports: 'brevity',
      reasoning: 'Message is only 2 words'
    }
  ];
  
  const formatted = formatEvidence(evidence);
  
  assertEquals(formatted.includes('😊'), true);
  assertEquals(formatted.includes('emoji'), true);
  assertEquals(formatted.includes('length'), true);
});

