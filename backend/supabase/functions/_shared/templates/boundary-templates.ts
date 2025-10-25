/**
 * Templates for setting and maintaining boundaries
 * Critical for neurodivergent folks who struggle with people-pleasing
 */

import type { ResponseTemplate } from './declining-templates.ts';

export const BOUNDARY_TEMPLATES: ResponseTemplate[] = [
  {
    id: 'boundary_time',
    name: 'Time Boundary',
    situation: 'When someone expects you to be available 24/7',
    template: "I'm available to discuss this during {your_hours}. Can we schedule a time within those hours?",
    tone: 'direct',
    context: ['urgent', 'right now', 'immediately'],
    neurodivergent_friendly: true,
    customizable_fields: ['your_hours'],
  },
  {
    id: 'boundary_communication',
    name: 'Communication Preference',
    situation: 'When someone uses a communication method that doesn\'t work for you',
    template: "I process information better through {preferred_method}. Could we switch to that for this conversation?",
    tone: 'direct',
    context: ['call', 'video', 'meeting', 'voice'],
    neurodivergent_friendly: true,
    customizable_fields: ['preferred_method'],
  },
  {
    id: 'boundary_topic',
    name: 'Topic Boundary',
    situation: 'When someone brings up something you don\'t want to discuss',
    template: "I'm not comfortable discussing {topic}. Let's talk about something else.",
    tone: 'direct',
    context: ['personal', 'private', 'politics', 'religion'],
    neurodivergent_friendly: true,
    customizable_fields: ['topic'],
  },
  {
    id: 'boundary_physical',
    name: 'Physical Boundary',
    situation: 'When someone violates your physical space',
    template: "I need a bit more personal space. Could you {specific_request}?",
    tone: 'direct',
    context: ['hug', 'touch', 'close'],
    neurodivergent_friendly: true,
    customizable_fields: ['specific_request'],
  },
  {
    id: 'boundary_reassert',
    name: 'Re-Assert Boundary',
    situation: 'When someone ignores a boundary you\'ve already set',
    template: "I mentioned before that {previous_boundary}. I need you to respect that.",
    tone: 'direct',
    context: ['again', 'still', 'keep'],
    neurodivergent_friendly: true,
    customizable_fields: ['previous_boundary'],
  },
  {
    id: 'boundary_emotional',
    name: 'Emotional Labor Boundary',
    situation: 'When someone expects you to manage their emotions',
    template: "I care about you, but I'm not in a place to provide emotional support right now. Have you considered {alternative_resource}?",
    tone: 'polite',
    context: ['vent', 'support', 'help', 'listen'],
    neurodivergent_friendly: true,
    customizable_fields: ['alternative_resource'],
  },
  {
    id: 'boundary_work_life',
    name: 'Work-Life Boundary',
    situation: 'When work contacts you outside work hours',
    template: "I'm off the clock right now. I'll address this during my next work day ({day}). If it's truly urgent, please contact {emergency_contact}.",
    tone: 'direct',
    context: ['weekend', 'evening', 'vacation', 'off'],
    neurodivergent_friendly: true,
    customizable_fields: ['day', 'emergency_contact'],
  },
  {
    id: 'boundary_advice',
    name: 'Unwanted Advice Boundary',
    situation: 'When someone gives advice you didn\'t ask for',
    template: "I appreciate your concern, but I'm not looking for advice right now. I just needed to {what_you_need}.",
    tone: 'polite',
    context: ['should', 'you need to', 'try this'],
    neurodivergent_friendly: true,
    customizable_fields: ['what_you_need'],
  },
];

