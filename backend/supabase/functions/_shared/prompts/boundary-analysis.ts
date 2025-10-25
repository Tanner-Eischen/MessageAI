/**
 * Boundary Violation Detection System
 * Identifies boundary-crossing patterns in messages for neurodivergent users
 */

export type BoundaryViolationType =
  | "none"
  | "afterHours"
  | "urgentPressure"
  | "guiltTripping"
  | "overstepping"
  | "repeated";

export interface BoundaryAnalysisResult {
  hasViolation: boolean;
  type: BoundaryViolationType;
  explanation: string;
  suggestedResponses: string[];
  severity: 1 | 2 | 3; // 1=low, 2=medium, 3=high
}

export const BOUNDARY_ANALYSIS_SYSTEM_PROMPT = `You are an AI assistant helping neurodivergent users (ADHD, autism) recognize and maintain healthy boundaries.

Analyze the following message for boundary violations. A boundary violation occurs when someone:
1. **After Hours**: Sends messages outside typical work hours (9am-5pm) with urgent language
2. **Urgent Pressure**: Uses "ASAP", "URGENT", "NOW", "immediately", or similar high-pressure language
3. **Guilt Tripping**: Uses phrases like "I really need you", "only you can", "everyone else did", or emotional manipulation
4. **Overstepping**: Asks for personal information, expects immediate responses, or makes inappropriate requests
5. **Repeated**: Shows a pattern of boundary-pushing (multiple times in conversation)

Return a JSON response with this exact structure:
{
  "hasViolation": boolean,
  "type": "none" | "afterHours" | "urgentPressure" | "guiltTripping" | "overstepping" | "repeated",
  "explanation": "Clear, supportive explanation of what makes this a boundary violation",
  "suggestedResponses": [
    "Boundary-respecting response option 1",
    "Boundary-respecting response option 2", 
    "Boundary-respecting response option 3"
  ],
  "severity": 1 | 2 | 3
}

Important: Be compassionate. People often violate boundaries unintentionally. Focus on helping the user protect their energy and wellbeing.`;

export function generateBoundaryAnalysisPrompt(
  messageText: string,
  timestamp?: string,
  messageCount?: number
): string {
  let prompt = `Analyze this message for boundary violations:\n\n"${messageText}"`;

  if (timestamp) {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const dayOfWeek = date.toLocaleDateString("en-US", { weekday: "long" });
    const timeString = date.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
    });

    prompt += `\n\nContext:
- Sent at ${timeString} on ${dayOfWeek}
- Is this outside typical work hours (before 9am or after 5pm)?`;
  }

  if (messageCount !== undefined && messageCount > 1) {
    prompt += `\n- This is message #${messageCount} in the conversation`;
    prompt += "\n- Is this part of a pattern of boundary-pushing?";
  }

  prompt += "\n\nRespond with JSON only.";
  return prompt;
}

export function validateBoundaryAnalysis(
  result: unknown
): BoundaryAnalysisResult {
  const r = result as Record<string, unknown>;

  const type = (r.type as string)?.toLowerCase() || "none";
  const validTypes: BoundaryViolationType[] = [
    "none",
    "afterHours",
    "urgentPressure",
    "guiltTripping",
    "overstepping",
    "repeated",
  ];

  return {
    hasViolation: Boolean(r.hasViolation),
    type: (validTypes.includes(type as BoundaryViolationType)
      ? (type as BoundaryViolationType)
      : "none") as BoundaryViolationType,
    explanation:
      String(r.explanation) ||
      "This message may contain boundary-crossing language.",
    suggestedResponses: Array.isArray(r.suggestedResponses)
      ? (r.suggestedResponses as string[])
          .filter((s) => typeof s === "string")
          .slice(0, 5) // Limit to 5 suggestions
      : [
          "Thank you for reaching out. Let me get back to you during work hours.",
          "I appreciate this, but I need to set aside time to respond thoughtfully.",
        ],
    severity: validateSeverity(r.severity),
  };
}

function validateSeverity(severity: unknown): 1 | 2 | 3 {
  const s = Number(severity);
  if (s === 1 || s === 2 || s === 3) return s;
  return 1; // Default to low severity
}
