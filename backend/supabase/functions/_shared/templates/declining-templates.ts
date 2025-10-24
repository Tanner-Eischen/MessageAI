/**
 * Templates for declining invitations, requests, or commitments
 * Helps people-pleasers and those who struggle to say no
 */

export interface ResponseTemplate {
  id: string;
  name: string;
  situation: string; // When to use this
  template: string; // The actual text
  tone: 'polite' | 'casual' | 'direct' | 'apologetic';
  context: string[]; // Keywords that trigger this template
  neurodivergent_friendly: boolean;
  customizable_fields?: string[]; // Fields user can fill in
}

export const DECLINING_TEMPLATES: ResponseTemplate[] = [
  {
    id: 'decline_polite',
    name: 'Polite Decline',
    situation: 'When you need to say no professionally',
    template: "Thank you for thinking of me! Unfortunately, I won't be able to {activity} {timeframe}. I appreciate your understanding.",
    tone: 'polite',
    context: ['can you', 'would you', 'invitation', 'request'],
    neurodivergent_friendly: true,
    customizable_fields: ['activity', 'timeframe'],
  },
  {
    id: 'decline_no_explanation',
    name: 'Direct Decline (No Explanation Required)',
    situation: 'When you don\'t owe an explanation',
    template: "Thanks for the invite, but I'm not able to join this time.",
    tone: 'direct',
    context: ['party', 'event', 'hangout', 'gathering'],
    neurodivergent_friendly: true,
  },
  {
    id: 'decline_with_alternative',
    name: 'Decline with Counter-Offer',
    situation: 'When you want to participate but need different terms',
    template: "I can't {original_request}, but I could {alternative}. Would that work?",
    tone: 'casual',
    context: ['meeting', 'call', 'hangout'],
    neurodivergent_friendly: true,
    customizable_fields: ['original_request', 'alternative'],
  },
  {
    id: 'decline_overcommitted',
    name: 'Already Overcommitted',
    situation: 'When your schedule is full',
    template: "I'd love to, but I'm already stretched thin this {period}. Can we revisit this {later_time}?",
    tone: 'polite',
    context: ['project', 'commitment', 'volunteer'],
    neurodivergent_friendly: true,
    customizable_fields: ['period', 'later_time'],
  },
  {
    id: 'decline_capacity',
    name: 'At Capacity (Mental Health)',
    situation: 'When you need to protect your energy',
    template: "I really appreciate you thinking of me, but I need to be mindful of my capacity right now. I'll have to pass on this one.",
    tone: 'apologetic',
    context: ['favor', 'help', 'support'],
    neurodivergent_friendly: true,
  },
  {
    id: 'decline_not_interested',
    name: 'Not Interested (Honest)',
    situation: 'When something just isn\'t for you',
    template: "Thanks for thinking of me, but {activity} isn't really my thing. Hope you find someone who's a better fit!",
    tone: 'casual',
    context: ['invitation', 'hobby', 'activity'],
    neurodivergent_friendly: true,
    customizable_fields: ['activity'],
  },
  {
    id: 'decline_work_request',
    name: 'Decline Extra Work',
    situation: 'When your boss/coworker asks for more work',
    template: "I want to help, but I'm currently focused on {current_priorities}. If this is urgent, which of my current tasks should I deprioritize?",
    tone: 'polite',
    context: ['project', 'deadline', 'work', 'task'],
    neurodivergent_friendly: true,
    customizable_fields: ['current_priorities'],
  },
  {
    id: 'decline_delay',
    name: 'Not Now, Maybe Later',
    situation: 'When you need more time to decide',
    template: "I need some time to think about this. Can I get back to you by {date/time}?",
    tone: 'direct',
    context: ['decision', 'commitment', 'request'],
    neurodivergent_friendly: true,
    customizable_fields: ['date/time'],
  },
];

