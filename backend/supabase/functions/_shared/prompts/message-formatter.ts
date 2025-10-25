/**
 * Formats long messages into more digestible versions
 * Helps info-dumpers communicate without overwhelming
 */

export interface FormattingOptions {
  condense: boolean;      // Make it shorter
  chunk: boolean;         // Break into sections
  add_tldr: boolean;      // Add summary at top
  add_structure: boolean; // Add headers/bullets
}

export interface FormattedMessage {
  original_length: number;
  formatted_message: string;
  formatting_applied: string[];
  character_count: number;
  estimated_read_time: string; // "30 seconds", "2 minutes"
}

export const MESSAGE_FORMATTING_PROMPT = `You are helping someone format a message to be more digestible.

**Formatting Options Available:**

1. **CONDENSE** - Reduce length while keeping key points
   - Remove redundancy
   - Tighten language
   - Keep essential info only
   - Target: 50-70% of original length

2. **CHUNK** - Break into logical sections with headers
   - Add section headers
   - Group related ideas
   - Use bullet points
   - Add white space

3. **ADD_TLDR** - Add brief summary at top
   - 1-2 sentence overview
   - Clearly labeled "TL;DR:"
   - Captures main point

4. **ADD_STRUCTURE** - Improve organization
   - Add headings
   - Use numbered lists
   - Add emphasis (bold key phrases)
   - Improve flow

**Example Input:**
"I just finished reading this amazing book about productivity and it completely changed how I think about time management! The author argues that we shouldn't try to do more things but rather focus on doing the right things and one of the key concepts is something called time blocking where you schedule specific blocks of time for specific tasks instead of just having a to-do list and the research shows that this is way more effective because our brains work better when we're focused on one thing at a time rather than constantly switching between tasks which creates cognitive load and there's also this fascinating part about how successful people structure their mornings..."

**Example Output (CONDENSE + CHUNK + ADD_TLDR):**

TL;DR: Just read a game-changing book on productivity that recommends time blocking over to-do lists.

**Key Concept: Time Blocking**
- Schedule specific time blocks for specific tasks
- More effective than to-do lists
- Reduces cognitive load from task-switching

**The Science**
- Our brains work better with focused attention
- Constant task-switching drains mental energy
- Successful people structure their mornings intentionally

**Response Format:**
{
  "original_length": 450,
  "formatted_message": "...",
  "formatting_applied": ["condense", "chunk", "add_tldr"],
  "character_count": 280,
  "estimated_read_time": "45 seconds"
}`;

export function calculateReadTime(characterCount: number): string {
  // Average reading speed: 200-250 words/min = ~1000 chars/min
  const minutes = Math.ceil(characterCount / 1000);
  if (minutes < 1) return '30 seconds';
  if (minutes === 1) return '1 minute';
  return `${minutes} minutes`;
}

export function generateFormattingPrompt(
  message: string,
  options: FormattingOptions
): string {
  const selectedOptions = Object.entries(options)
    .filter(([_, enabled]) => enabled)
    .map(([option]) => option.toUpperCase())
    .join(', ');

  return `**Original Message:**
"${message}"

**Requested Formatting:**
${selectedOptions}

Apply the requested formatting and return the result.`;
}

