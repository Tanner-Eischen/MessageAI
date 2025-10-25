# Response Parsing Debugging Guide

## Overview

You have **silent response parsing failures** in the tone analysis pipeline. The issue occurs when:
1. OpenAI returns a 200 response
2. The response contains invalid or malformed JSON
3. The JSON parse attempt fails silently OR validation fails

This guide helps you identify WHERE in the pipeline the failure occurs.

## Recent Enhancements (Oct 25, 2025)

I've added comprehensive logging throughout the response parsing pipeline:

### 1. **OpenAI Client Logging** (`openai-client.ts`)

#### `parseJSONResponse` method:
```
🔍 Raw response from OpenAI: [first 200 chars]
✨ Cleaned response: [first 200 chars after markdown removal]
✅ JSON parsed successfully
❌ JSON parsing failed! [error details + response context]
```

#### `sendMessageForJSON` method:
```
📤 Preparing JSON request to OpenAI...
   System prompt length: [length]
   User message length: [length]
📥 Received response from OpenAI, attempting to parse...
🎯 Successfully parsed JSON response
💥 Failed to get JSON response: [error]
```

### 2. **Validation Logging** (`enhanced-tone-analysis.ts`)

#### `validateToneAnalysis` function:
```
🔍 Validating tone analysis result...
Received result: [full JSON structure]
✅ Tone normalized: "invalid" -> "Friendly"
❌ Invalid tone: [tone value]
❌ Invalid urgency level: [value]
❌ Invalid intensity: [value]
✅ Validation passed!
```

### 3. **Function Execution Logging** (`ai_analyze_tone/index.ts`)

```
🔍 Analyzing message [message_id first 8 chars]...
🏷️ Tone indicators found: [indicators]
💭 Figurative language: [detected examples]
📤 Sending request to OpenAI...
📥 Received response from OpenAI
Analysis result structure:
  - tone: [value]
  - urgency_level: [value]
  - intent: [value]
  - confidence_score: [value]
  - intensity: [value]
  - secondary_tones: [count]
  - hasContextFlags: [boolean]
🔍 Validating analysis result...
✅ Validation successful
🧠 Anxiety assessment: [result]
✅ Analysis complete: [tone] ([urgency])
💾 Analysis stored successfully
```

## How to View Logs

### Supabase Dashboard Method

1. Go to **Supabase Console** → Your Project
2. Navigate to **Functions** → `ai_analyze_tone`
3. Click **Logs** tab
4. Look for execution with matching `execution_id`
5. View the **"Logs"** section (not just the response)

### Command Line Method (via Supabase CLI)

```bash
supabase functions list
supabase functions fetch ai_analyze_tone --logs
```

## Diagnosing Failures

### Scenario 1: ✅ Success Path
```
📤 Preparing JSON request to OpenAI...
📥 Received response from OpenAI, attempting to parse...
🔍 Raw response from OpenAI: {"tone": "Friendly", ...
✨ Cleaned response: {"tone": "Friendly", ...
✅ JSON parsed successfully
🔍 Validating tone analysis result...
Received result: {"tone": "Friendly", ...
✅ Tone normalized: "friendly" -> "Friendly"
✅ Validation passed!
✅ Analysis complete: Friendly (Low)
```

### Scenario 2: ❌ JSON Parsing Failure
```
📤 Preparing JSON request to OpenAI...
📥 Received response from OpenAI, attempting to parse...
🔍 Raw response from OpenAI: something that's not JSON
❌ JSON parsing failed!
Error: Unexpected token
Response preview: {invalid json...
💥 Failed to get JSON response: Error: Failed to parse JSON...
```
**Cause**: OpenAI returned non-JSON response or response was truncated
**Fix**: Check if max_tokens is too low

### Scenario 3: ❌ Validation Failure - Invalid Tone
```
✅ JSON parsed successfully
🔍 Validating tone analysis result...
Received result: {"tone": "ANGRY", "urgency_level": "High", ...
❌ Invalid tone: "ANGRY"
❌ Valid tones: Friendly, Professional, Urgent, ...
```
**Cause**: OpenAI chose a tone not in VALID_TONES list
**Fix**: Update system prompt to enforce valid tones

### Scenario 4: ❌ Validation Failure - Invalid Urgency
```
✅ JSON parsed successfully
🔍 Validating tone analysis result...
Received result: {"tone": "Friendly", "urgency_level": "Very High", ...
❌ Invalid urgency level: "Very High"
❌ Valid urgency levels: Low, Medium, High, Critical
```
**Cause**: OpenAI returned non-standard urgency level
**Fix**: Enforce capitalization in system prompt

### Scenario 5: ⚠️ Empty Response
```
📤 Preparing JSON request to OpenAI...
📥 Received response from OpenAI, attempting to parse...
⚠️ Empty response content from OpenAI
🔍 Raw response from OpenAI: 
❌ JSON parsing failed!
Error: Unexpected end of JSON input
```
**Cause**: OpenAI returned empty response or timeout
**Fix**: Check API key validity, increase timeout

## Key Metrics from Recent Execution

From your event metadata:
- **Status**: 200 ✅
- **Execution Time**: 10,031 ms ⚠️ (slightly slow, acceptable)
- **Response Size**: 1,103 bytes ✅ (reasonable)
- **Auth**: Authenticated ✅

## Next Steps

1. **Check the logs** in Supabase dashboard for the execution ID: `5888a6d9-0e81-4c1f-bb45-8324a65eb7c6`
2. **Find which scenario** matches your logs
3. **Copy the exact error message** and we'll fix it
4. **Look for**: 
   - Any `❌` or `💥` messages
   - What comes AFTER "Received response from OpenAI"
   - The actual error in the "Response preview"

## Common Fixes

| Error | Fix |
|-------|-----|
| `Unexpected token` | JSON parsing issue - check response format |
| `Invalid tone: "..."` | Update VALID_TONES or system prompt |
| `Invalid urgency level` | Check case sensitivity |
| `Empty response` | Increase max_tokens or check API quota |
| `Timeout` | Already fixed with try/catch wrapping |

## Response Format Validation

The system expects this exact structure:

```typescript
{
  "tone": "Friendly",                    // Must be from VALID_TONES
  "urgency_level": "High",               // Must be: Low, Medium, High, Critical
  "intent": "Expressing concern",        // Non-empty string
  "confidence_score": 0.85,              // Number 0-1
  "intensity": "medium",                 // Optional: very_low, low, medium, high, very_high
  "secondary_tones": ["Empathetic"],     // Optional: array of valid tones
  "context_flags": {                     // Optional
    "sarcasm_detected": false,
    "tone_indicator_present": false,
    "ambiguous": false
  },
  "reasoning": "..."                     // Optional
}
```

## Testing the Fix

After checking logs, to test end-to-end:

```bash
# From frontend
await supabase.functions.invoke('ai_analyze_tone', {
  body: {
    message_id: 'test-id-12345',
    message_body: 'This is a test message',
    conversation_context: [],
  },
});

# Check logs for all the 📤📥 messages
```

---

**Last Updated**: Oct 25, 2025  
**Related Files**:
- `backend/supabase/functions/_shared/openai-client.ts` (logging enhancements)
- `backend/supabase/functions/_shared/prompts/enhanced-tone-analysis.ts` (validation logging)
- `backend/supabase/functions/ai_analyze_tone/index.ts` (function execution logging)
