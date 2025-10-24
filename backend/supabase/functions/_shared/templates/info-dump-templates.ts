/**
 * Templates for sharing enthusiasm without overwhelming recipients
 * Helps neurodivergent folks who info-dump about special interests
 */

import type { ResponseTemplate } from './declining-templates.ts';

export const INFO_DUMP_TEMPLATES: ResponseTemplate[] = [
  {
    id: 'infodump_intro',
    name: 'Info-Dump with Warning',
    situation: 'When you want to share a lot about something you love',
    template: "I'm really excited about {topic}! Fair warning: I could talk about this for hours 😊 Are you interested in hearing more?",
    tone: 'casual',
    context: ['excited', 'interesting', 'found', 'learned'],
    neurodivergent_friendly: true,
    customizable_fields: ['topic'],
  },
  {
    id: 'infodump_chunked',
    name: 'Info-Dump in Chunks',
    situation: 'When you want to share but keep it digestible',
    template: "Quick version: {short_summary}\n\nWant the details? I can break it down into:\n1. {aspect_1}\n2. {aspect_2}\n3. {aspect_3}\n\nLet me know what interests you!",
    tone: 'casual',
    context: ['explain', 'tell', 'share'],
    neurodivergent_friendly: true,
    customizable_fields: ['short_summary', 'aspect_1', 'aspect_2', 'aspect_3'],
  },
  {
    id: 'infodump_structured',
    name: 'Structured Share',
    situation: 'When you want to info-dump in an organized way',
    template: "**The Short Version:** {tldr}\n\n**Why It's Cool:** {hook}\n\n**The Details** (optional read):\n{detailed_info}\n\n**Bottom Line:** {conclusion}",
    tone: 'casual',
    context: ['fascinating', 'amazing', 'incredible'],
    neurodivergent_friendly: true,
    customizable_fields: ['tldr', 'hook', 'detailed_info', 'conclusion'],
  },
  {
    id: 'infodump_ask_permission',
    name: 'Ask Permission First',
    situation: 'When you\'re not sure if they want to hear it',
    template: "I just learned something really interesting about {topic}. Do you have a few minutes for me to geek out about it? No pressure if not!",
    tone: 'casual',
    context: ['cool', 'interesting', 'fascinating'],
    neurodivergent_friendly: true,
    customizable_fields: ['topic'],
  },
  {
    id: 'infodump_link',
    name: 'Share a Link Instead',
    situation: 'When a link can do the explaining',
    template: "This {type_of_content} explains it way better than I could: {link}\n\nThe part that blew my mind: {specific_detail}",
    tone: 'casual',
    context: ['article', 'video', 'study', 'research'],
    neurodivergent_friendly: true,
    customizable_fields: ['type_of_content', 'link', 'specific_detail'],
  },
];

