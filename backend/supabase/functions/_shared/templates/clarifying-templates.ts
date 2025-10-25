/**
 * Templates for asking for clarification
 * Helps when you need things explained more clearly
 */

import type { ResponseTemplate } from './declining-templates.ts';

export const CLARIFYING_TEMPLATES: ResponseTemplate[] = [
  {
    id: 'clarify_misunderstand',
    name: 'Admit Confusion',
    situation: 'When you don\'t understand something',
    template: "I want to make sure I understand correctly. Are you saying {your_interpretation}?",
    tone: 'direct',
    context: ['confused', 'unclear', 'not sure'],
    neurodivergent_friendly: true,
    customizable_fields: ['your_interpretation'],
  },
  {
    id: 'clarify_literal',
    name: 'Ask for Literal Meaning',
    situation: 'When you need things stated directly',
    template: "I'm having trouble reading between the lines. Could you tell me directly what you need from me?",
    tone: 'direct',
    context: ['ambiguous', 'vague', 'hint'],
    neurodivergent_friendly: true,
  },
  {
    id: 'clarify_instructions',
    name: 'Request Specific Instructions',
    situation: 'When instructions are too vague',
    template: "Could you break that down into specific steps? It helps me to have a clear list of what to do.",
    tone: 'polite',
    context: ['task', 'project', 'assignment'],
    neurodivergent_friendly: true,
  },
  {
    id: 'clarify_tone',
    name: 'Check Tone',
    situation: 'When you\'re not sure if they\'re upset',
    template: "I can't tell if you're upset or just being direct. Could you let me know where we stand?",
    tone: 'direct',
    context: ['ok', 'fine', 'whatever'],
    neurodivergent_friendly: true,
  },
];

