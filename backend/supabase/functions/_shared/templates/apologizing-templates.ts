/**
 * Templates for appropriate apologies
 * Helps avoid over-apologizing (common in neurodivergent folks)
 */

import type { ResponseTemplate } from './declining-templates.ts';

export const APOLOGIZING_TEMPLATES: ResponseTemplate[] = [
  {
    id: 'apology_genuine',
    name: 'Genuine Apology',
    situation: 'When you actually did something wrong',
    template: "I'm sorry for {what_you_did}. I understand that {impact}. Going forward, I'll {corrective_action}.",
    tone: 'apologetic',
    context: ['mistake', 'wrong', 'messed up'],
    neurodivergent_friendly: true,
    customizable_fields: ['what_you_did', 'impact', 'corrective_action'],
  },
  {
    id: 'apology_no_need',
    name: 'Replace Unnecessary Apology',
    situation: 'When you\'re apologizing out of habit',
    template: "Thank you for {what_they_did}. I appreciate {specific_thing}.",
    tone: 'polite',
    context: ['sorry for', 'apologies for'],
    neurodivergent_friendly: true,
    customizable_fields: ['what_they_did', 'specific_thing'],
  },
  {
    id: 'apology_delay',
    name: 'Apology for Delay',
    situation: 'When you took longer than expected',
    template: "Thanks for your patience! Here's {what_they_asked_for}.",
    tone: 'casual',
    context: ['late', 'delay', 'took long'],
    neurodivergent_friendly: true,
    customizable_fields: ['what_they_asked_for'],
  },
];

