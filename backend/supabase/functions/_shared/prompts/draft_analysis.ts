/**
 * Draft Analysis for Message Confidence Checking
 * Extends enhanced tone analysis for draft/outgoing messages
 */

import {
  ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT,
  type ToneAnalysisResult,
} from './enhanced-tone-analysis.ts';

import {
  SITUATION_DETECTION_PROMPT,
  detectSituation,
  type SituationType,
  type SituationDetectionResult,
} from './situation-detector.ts';

import {
  ALL_TEMPLATES,
  DECLINING_TEMPLATES,
  BOUNDARY_TEMPLATES,
  INFO_DUMP_TEMPLATES,
  APOLOGIZING_TEMPLATES,
  CLARIFYING_TEMPLATES,
  type ResponseTemplate,
} from '../templates/index.ts';

export interface DraftAnalysisContext {
  draftMessage: string;
  conversationHistory?: string[];
  relationshipType?: 'boss' | 'colleague' | 'friend' | 'family' | 'client' | 'none';
  conversationTone?: string; // From previous tone analysis
  recipientInfo?: {
    name?: string;
    role?: string;
  };
}

export interface DraftAnalysisResult extends ToneAnalysisResult {
  // Extends tone analysis with draft-specific fields
  confidence_score: number; // 0-100
  appropriateness: 'excellent' | 'good' | 'okay' | 'needs_work';
  suggestions: string[];
  warnings: string[];
  strengths: string[];
  
  // NEW: Situation detection and template suggestions
  situation_detection?: SituationDetectionResult;
}

/**
 * Enhanced prompt for draft analysis - extends existing tone analysis with situation detection
 */
export const DRAFT_ANALYSIS_SYSTEM_PROMPT = `${ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT}

**ADDITIONAL CONTEXT: This is a DRAFT message being composed**

${SITUATION_DETECTION_PROMPT}

Provide additional draft-specific guidance to help the user send with confidence:

1. **Confidence Score** (0-100): How ready is this message to send?
   - 90-100: Excellent - Ready to send, no changes needed
   - 75-89: Good - Minor polish could help, but solid overall
   - 60-74: Okay - Some improvements recommended
   - Below 60: Needs Work - Consider revising before sending

2. **Appropriateness**: Overall assessment (excellent/good/okay/needs_work)

3. **Strengths** (What works well):
   - Highlight positive aspects
   - Encourage what's already good
   - Build confidence

4. **Suggestions** (Maximum 3 specific improvements):
   - Actionable changes
   - Prioritize most impactful
   - Be constructive

5. **Warnings** (Red flags to address):
   - Tone mismatches for relationship context
   - Potentially offensive/ambiguous phrasing
   - Missing key information

**Response Format (JSON):**
{
  "tone": "one of 23 categories",
  "intensity": "one of 5 levels",
  "urgency_level": "one of 4 levels",
  "intent": "3-8 word description",
  "confidence_score": 85,
  "appropriateness": "good",
  "strengths": [
    "Clear and direct communication",
    "Appropriate level of formality"
  ],
  "suggestions": [
    "Consider adding a brief greeting",
    "Could specify deadline more explicitly"
  ],
  "warnings": [],
  "context_flags": {
    "sarcasm_detected": false,
    "tone_indicator_present": false,
    "ambiguous": false
  },
  "situation_detection": {
    "situation_type": "declining",
    "confidence": 0.85,
    "reasoning": "Draft contains decline language",
    "suggested_templates": ["decline_polite", "decline_with_alternative"]
  },
  "reasoning": "Message is professional and clear. Confidence is high..."
}`;

export function generateDraftAnalysisPrompt(context: DraftAnalysisContext): string {
  let prompt = `Analyze this DRAFT message before sending:\n\n`;
  prompt += `**Draft Message:**\n"${context.draftMessage}"\n\n`;
  
  if (context.relationshipType && context.relationshipType !== 'none') {
    prompt += `**Relationship Context:** ${context.relationshipType}\n`;
  }
  
  if (context.conversationTone) {
    prompt += `**Recent Conversation Tone:** ${context.conversationTone}\n`;
  }
  
  if (context.conversationHistory && context.conversationHistory.length > 0) {
    prompt += `**Recent Messages (for context):**\n`;
    context.conversationHistory.slice(-3).forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
    prompt += '\n';
  }
  
  if (context.recipientInfo?.name || context.recipientInfo?.role) {
    prompt += `**Recipient:**\n`;
    if (context.recipientInfo.name) prompt += `- Name: ${context.recipientInfo.name}\n`;
    if (context.recipientInfo.role) prompt += `- Role: ${context.recipientInfo.role}\n`;
    prompt += '\n';
  }
  
  prompt += `Provide your analysis in JSON format as specified above.`;
  
  return prompt;
}

export function validateDraftAnalysis(result: any): DraftAnalysisResult {
  // Validate confidence score
  if (typeof result.confidence_score !== 'number' || 
      result.confidence_score < 0 || 
      result.confidence_score > 100) {
    throw new Error('Invalid confidence score');
  }
  
  // Validate appropriateness
  const validAppropriateness = ['excellent', 'good', 'okay', 'needs_work'];
  if (!validAppropriateness.includes(result.appropriateness)) {
    throw new Error('Invalid appropriateness level');
  }
  
  // Validate tone (inherited from ToneAnalysisResult)
  if (!result.tone || typeof result.tone !== 'string') {
    throw new Error('Invalid tone');
  }
  
  return {
    // Tone analysis fields
    tone: result.tone,
    intensity: result.intensity,
    urgency_level: result.urgency_level,
    intent: result.intent,
    confidence_score: result.confidence_score,
    reasoning: result.reasoning,
    context_flags: result.context_flags,
    
    // Draft-specific fields
    appropriateness: result.appropriateness,
    suggestions: result.suggestions || [],
    warnings: result.warnings || [],
    strengths: result.strengths || [],
    
    // NEW: Situation detection
    situation_detection: result.situation_detection,
  };
}

/**
 * Get suggested templates based on detected situation type
 */
export function getSuggestedTemplates(situationType: SituationType): ResponseTemplate[] {
  // Map situation types to template collections
  const templateMap: Record<SituationType, ResponseTemplate[]> = {
    declining: DECLINING_TEMPLATES,
    boundary_setting: BOUNDARY_TEMPLATES,
    info_dumping: INFO_DUMP_TEMPLATES,
    apologizing: APOLOGIZING_TEMPLATES,
    clarifying: CLARIFYING_TEMPLATES,
    casual_chat: [],
    work_professional: [],
    emotional_support: [],
    unknown: [],
  };
  
  return templateMap[situationType] || [];
}

/**
 * Find templates matching specific keywords from the draft
 */
export function findMatchingTemplates(
  draftMessage: string,
  maxResults: number = 5
): ResponseTemplate[] {
  const messageLower = draftMessage.toLowerCase();
  const matches: Array<{ template: ResponseTemplate; score: number }> = [];
  
  for (const template of ALL_TEMPLATES) {
    let score = 0;
    
    // Check context keywords
    for (const keyword of template.context) {
      if (messageLower.includes(keyword.toLowerCase())) {
        score += 1;
      }
    }
    
    // Boost score for neurodivergent-friendly templates
    if (template.neurodivergent_friendly) {
      score += 0.5;
    }
    
    if (score > 0) {
      matches.push({ template, score });
    }
  }
  
  // Sort by score and return top results
  matches.sort((a, b) => b.score - a.score);
  return matches.slice(0, maxResults).map(m => m.template);
}

