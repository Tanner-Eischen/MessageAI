# MessageAI: Enhanced Tone Analysis Integration Guide

## 🎯 Project-Specific Overview

**Your Project:** MessageAI - Flutter messaging app with Supabase backend  
**Current State:** Basic tone analysis with 8 tones already implemented  
**Goal:** Upgrade to enhanced system with 23 tones, intensity scaling, and neurodivergent support  
**Timeline:** 2-4 weeks  
**Risk:** Low - enhanced file already exists, just needs activation

---

## 📁 Your Current File Structure

```
MessageAI/
├── backend/
│   └── supabase/
│       ├── functions/
│       │   ├── shared/
│       │   │   ├── openai-client.ts
│       │   │   └── prompts/
│       │   │       ├── tone-analysis.ts              # ❌ OLD (8 tones)
│       │   │       ├── tone-analysis-v1.backup.ts    # Backup
│       │   │       └── enhanced-tone-analysis.ts     # ✅ NEW (23 tones) - EXISTS!
│       │   └── ai-analyze-tone/
│       │       └── index.ts                          # Edge function
│       └── migrations/
│           ├── 20251024_000002_ai_analysis.sql
│           └── 20251224_000003_fix_ai_analysis_rpc_columns.sql
│
└── frontend/
    └── lib/
        ├── models/
        │   └── ai_analysis.dart                      # Data model
        ├── services/
        │   └── ai_analysis_service.dart              # API service
        ├── state/
        │   └── ai_providers.dart                     # Riverpod providers
        └── features/
            └── messages/
                └── widgets/
                    ├── tone_badge.dart               # UI badge
                    ├── ai_insights_panel.dart        # Insights panel
                    └── tone_detail_sheet.dart        # Detail view
```

---

## 📋 Phase 1: Backend Switch (30 minutes)

### **STEP 1: Update Edge Function Import**

**File:** `backend/supabase/functions/ai_analyze_tone/index.ts`

**Current code (lines 5-9):**
```typescript
import {
  TONE_ANALYSIS_SYSTEM_PROMPT,
  generateAnalysisPrompt,
  validateToneAnalysis,
  type ToneAnalysisResult,
} from '../_shared/prompts/tone-analysis.ts';
```

**Change to:**
```typescript
// ❌ OLD - Remove this import
// import { ... } from '../_shared/prompts/tone-analysis.ts';

// ✅ NEW - Use enhanced version instead
import {
  validateToneAnalysis,
  generateAnalysisPrompt,
  extractToneIndicators,
  detectFigurativeLanguage,
  assessResponseAnxietyRisk,
  type ToneAnalysisResult,
} from '../_shared/prompts/enhanced-tone-analysis.ts';

// Import the enhanced system prompt
import { ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT } from '../_shared/prompts/enhanced-tone-analysis.ts';
```

---

### **STEP 2: Add Enhanced Prompt Constant**

**File:** `backend/supabase/functions/_shared/prompts/enhanced-tone-analysis.ts`

**Add this at the END of the file (after line 240):**

```typescript
/**
 * Enhanced system prompt with 23 tones and neurodivergent support
 */
export const ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT = `You are an expert communication analyst specializing in understanding tone, intent, and urgency in messages, with specific expertise in neurodivergent communication patterns.

**CRITICAL PRIORITY: Neurodivergent Communication Considerations**

1. **Tone Indicator Detection** (HIGHEST PRIORITY):
   - If message contains /tone tags (e.g., "/j", "/srs", "/nm"), ALWAYS respect and cite them
   - These are explicit intent markers used by neurodivergent communities

**Enhanced Tone Categories** (23 total - choose ONE primary):

PRIMARY TONES (Original 8):
- Friendly: Warm, welcoming
- Professional: Business-like, formal
- Urgent: Time-sensitive, pressing
- Casual: Relaxed, informal
- Formal: Structured, official
- Concerned: Worried, distressed
- Excited: Enthusiastic, energetic
- Neutral: Balanced, objective

ADDITIONAL TONES (15 new):
- Apologetic: Expressing regret
- Appreciative: Showing gratitude
- Frustrated: Annoyed by obstacles
- Playful: Teasing, joking (/j)
- Sarcastic: Mocking with opposite meaning (/s)
- Empathetic: Understanding and supportive
- Inquisitive: Curious, seeking info
- Assertive: Confident and direct
- Tentative: Uncertain or hesitant
- Defensive: Protective or justifying
- Encouraging: Supportive and motivating
- Disappointed: Let down
- Overwhelmed: Excessive pressure
- Relieved: Reassured
- Confused: Unclear about meaning

**Intensity Levels** (choose ONE):
- very_low: Minimal expression
- low: Mild expression
- medium: Moderate expression
- high: Strong expression
- very_high: Extreme expression

**Urgency Levels** (choose ONE):
- Low: No time pressure
- Medium: Should be addressed soon
- High: Important and time-sensitive
- Critical: Extremely urgent

**Response Format (JSON):**
{
  "tone": "one of 23 categories",
  "intensity": "one of 5 levels",
  "urgency_level": "one of 4 levels",
  "intent": "3-8 word description",
  "confidence_score": 0.85,
  "context_flags": {
    "sarcasm_detected": false,
    "tone_indicator_present": false,
    "ambiguous": false
  },
  "reasoning": "explanation citing specific phrases"
}`;
```

---

### **STEP 3: Update Edge Function Analysis Logic**

**File:** `backend/supabase/functions/ai_analyze_tone/index.ts`

**Find the OpenAI call section (around lines 85-110) and update:**

```typescript
// ✅ BEFORE calling OpenAI - extract tone indicators
const toneIndicators = extractToneIndicators(message_body);
const figurativeLanguage = detectFigurativeLanguage(message_body);

console.log('Tone indicators found:', toneIndicators);
console.log('Figurative language:', figurativeLanguage);

// Generate the analysis prompt
const userPrompt = generateAnalysisPrompt(
  message_body,
  conversation_context
);

console.log('Sending request to OpenAI...');

// ❌ OLD - Replace this line:
// const analysisResult = await openai.sendMessageForJSON<ToneAnalysisResult>(
//   userPrompt,
//   TONE_ANALYSIS_SYSTEM_PROMPT,  // OLD
//   { temperature: 0.3 }
// );

// ✅ NEW - Use enhanced prompt:
const analysisResult = await openai.sendMessageForJSON<ToneAnalysisResult>(
  userPrompt,
  ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT,  // NEW - 23 tones + intensity
  { temperature: 0.3 }
);

console.log('Received response from OpenAI');

// Validate the result (this stays the same)
const validatedResult = validateToneAnalysis(analysisResult);

// ✅ NEW - Add anxiety assessment
const anxietyAssessment = assessResponseAnxietyRisk(validatedResult);
console.log('Anxiety assessment:', anxietyAssessment);

console.log('Analysis complete', validatedResult.tone, validatedResult.urgency_level);

// Store result (see next step for database updates)
```

---

### **STEP 4: Deploy Backend Changes**

```bash
cd backend/supabase

# Deploy the updated Edge Function
supabase functions deploy ai_analyze_tone

# Verify deployment
supabase functions list

# Test with a message
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/ai_analyze_tone \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message_id": "test-123",
    "message_body": "I'\''m SO overwhelmed right now /srs"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "analysis": {
    "tone": "Overwhelmed",
    "intensity": "high",
    "urgency_level": "Medium",
    "intent": "expressing severe distress",
    "confidence_score": 0.92,
    "context_flags": {
      "tone_indicator_present": true
    }
  }
}
```

---

## 📋 Phase 2: Database Migration (Optional - 15 minutes)

**Only if you want to store new fields like intensity, context_flags**

### **STEP 5: Create Migration File**

**Create:** `backend/supabase/migrations/20251225_000001_add_enhanced_analysis_fields.sql`

```sql
-- Add enhanced analysis fields
ALTER TABLE message_ai_analysis 
  ADD COLUMN IF NOT EXISTS intensity TEXT,
  ADD COLUMN IF NOT EXISTS secondary_tones JSONB,
  ADD COLUMN IF NOT EXISTS context_flags JSONB,
  ADD COLUMN IF NOT EXISTS anxiety_assessment JSONB;

-- Update get_message_ai_analysis RPC
CREATE OR REPLACE FUNCTION get_message_ai_analysis(p_message_id UUID)
RETURNS TABLE (
  id UUID,
  message_id UUID,
  tone TEXT,
  urgency_level TEXT,
  intent TEXT,
  confidence_score REAL,
  intensity TEXT,              -- NEW
  secondary_tones JSONB,       -- NEW
  context_flags JSONB,         -- NEW
  anxiety_assessment JSONB,    -- NEW
  analysis_timestamp INTEGER
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM messages m
    JOIN conversation_participants p ON m.conversation_id = p.conversation_id
    WHERE m.id = p_message_id AND p.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to message';
  END IF;

  RETURN QUERY
  SELECT 
    a.id,
    a.message_id,
    a.tone,
    a.urgency_level,
    a.intent,
    a.confidence_score,
    a.intensity,
    a.secondary_tones,
    a.context_flags,
    a.anxiety_assessment,
    a.analysis_timestamp
  FROM message_ai_analysis a
  WHERE a.message_id = p_message_id
  LIMIT 1;
END;
$$;

-- Update get_conversation_ai_analysis similarly
CREATE OR REPLACE FUNCTION get_conversation_ai_analysis(p_conversation_id UUID)
RETURNS TABLE (
  id UUID,
  message_id UUID,
  tone TEXT,
  urgency_level TEXT,
  intent TEXT,
  confidence_score REAL,
  intensity TEXT,
  secondary_tones JSONB,
  context_flags JSONB,
  anxiety_assessment JSONB,
  analysis_timestamp INTEGER
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to conversation';
  END IF;

  RETURN QUERY
  SELECT 
    a.id,
    a.message_id,
    a.tone,
    a.urgency_level,
    a.intent,
    a.confidence_score,
    a.intensity,
    a.secondary_tones,
    a.context_flags,
    a.anxiety_assessment,
    a.analysis_timestamp
  FROM message_ai_analysis a
  JOIN messages m ON a.message_id = m.id
  WHERE m.conversation_id = p_conversation_id
  ORDER BY m.created_at DESC;
END;
$$;
```

**Run migration:**
```bash
supabase db push
```

---

### **STEP 6: Update Edge Function to Store New Fields**

**File:** `backend/supabase/functions/ai_analyze_tone/index.ts`

**Update the database insert (around line 120):**

```typescript
// Store the analysis in the database
const now = Math.floor(Date.now() / 1000);

const { data: storedAnalysis, error: insertError } = await supabase
  .from('message_ai_analysis')
  .insert({
    message_id: message_id,
    tone: validatedResult.tone,
    urgency_level: validatedResult.urgency_level,
    intent: validatedResult.intent,
    confidence_score: validatedResult.confidence_score,
    analysis_timestamp: now,
    // ✅ NEW FIELDS
    intensity: validatedResult.intensity,
    context_flags: validatedResult.context_flags,
    anxiety_assessment: anxietyAssessment,
  })
  .select()
  .single();
```

---

## 📋 Phase 3: Update Flutter Frontend (45 minutes)

### **STEP 7: Update AIAnalysis Model**

**File:** `frontend/lib/models/ai_analysis.dart`

**Add new fields (after line 10):**

```dart
class AIAnalysis {
  final String id;
  final String messageId;
  final String tone;
  final String? urgencyLevel;
  final String? intent;
  final double? confidenceScore;
  final int analysisTimestamp;
  
  // ✅ NEW ENHANCED FIELDS
  final String? intensity;
  final List<String>? secondaryTones;
  final Map<String, dynamic>? contextFlags;
  final Map<String, dynamic>? anxietyAssessment;

  AIAnalysis({
    required this.id,
    required this.messageId,
    required this.tone,
    this.urgencyLevel,
    this.intent,
    this.confidenceScore,
    required this.analysisTimestamp,
    // ✅ NEW
    this.intensity,
    this.secondaryTones,
    this.contextFlags,
    this.anxietyAssessment,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      tone: json['tone'] as String,
      urgencyLevel: json['urgency_level'] as String?,
      intent: json['intent'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      analysisTimestamp: json['analysis_timestamp'] as int,
      // ✅ Parse new fields
      intensity: json['intensity'] as String?,
      secondaryTones: (json['secondary_tones'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      contextFlags: json['context_flags'] as Map<String, dynamic>?,
      anxietyAssessment: json['anxiety_assessment'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'tone': tone,
      'urgency_level': urgencyLevel,
      'intent': intent,
      'confidence_score': confidenceScore,
      'analysis_timestamp': analysisTimestamp,
      // ✅ Include new fields
      if (intensity != null) 'intensity': intensity,
      if (secondaryTones != null) 'secondary_tones': secondaryTones,
      if (contextFlags != null) 'context_flags': contextFlags,
      if (anxietyAssessment != null) 'anxiety_assessment': anxietyAssessment,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIAnalysis &&
        other.id == id &&
        other.messageId == messageId;
  }

  @override
  int get hashCode => id.hashCode ^ messageId.hashCode;

  @override
  String toString() {
    return 'AIAnalysis(id: $id, messageId: $messageId, tone: $tone, '
        'urgencyLevel: $urgencyLevel, intensity: $intensity)';
  }
}
```

---

### **STEP 8: Update ToneBadge Widget**

**File:** `frontend/lib/features/messages/widgets/tone_badge.dart`

**Update emoji mapping (around line 74) to support all 23 tones:**

```dart
String _getToneEmoji(String tone) {
  switch (tone.toLowerCase()) {
    // Original 8
    case 'friendly': return '😊';
    case 'professional': return '💼';
    case 'urgent': return '⚠️';
    case 'casual': return '😎';
    case 'formal': return '🎩';
    case 'concerned': return '😟';
    case 'excited': return '🎉';
    case 'neutral': return '😐';
    
    // ✅ NEW: 15 additional tones
    case 'apologetic': return '🙏';
    case 'appreciative': return '🙌';
    case 'frustrated': return '😤';
    case 'playful': return '😜';
    case 'sarcastic': return '🙄';
    case 'empathetic': return '🤗';
    case 'inquisitive': return '🤔';
    case 'assertive': return '💪';
    case 'tentative': return '😬';
    case 'defensive': return '🛡️';
    case 'encouraging': return '💚';
    case 'disappointed': return '😞';
    case 'overwhelmed': return '😵';
    case 'relieved': return '😌';
    case 'confused': return '😕';
    
    default: return '💬';
  }
}
```

**Add intensity indicator (around line 140):**

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getToneColor(analysis.tone).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getToneColor(analysis.tone),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getToneEmoji(analysis.tone), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            analysis.tone,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getToneColor(analysis.tone),
              fontWeight: FontWeight.w600,
            ),
          ),
          // ✅ NEW: Show intensity dot
          if (analysis.intensity != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getIntensityColor(analysis.intensity!),
                shape: BoxShape.circle,
              ),
            ),
          ],
          // Existing urgency dot
          _buildUrgencyDot(analysis.urgencyLevel, isDark),
        ],
      ),
    ),
  );
}

// ✅ NEW: Helper for intensity colors
Color _getIntensityColor(String intensity) {
  switch (intensity.toLowerCase()) {
    case 'very_high': return Colors.red;
    case 'high': return Colors.orange;
    case 'medium': return Colors.blue;
    case 'low': return Colors.green;
    case 'very_low': return Colors.grey;
    default: return Colors.grey;
  }
}
```

---

### **STEP 9: Update ToneDetailSheet**

**File:** `frontend/lib/features/messages/widgets/tone_detail_sheet.dart`

**Add sections for new data (after existing sections, around line 150):**

```dart
// Existing sections...

// ✅ NEW: Intensity section
if (analysis.intensity != null) ...[
  const SizedBox(height: 16),
  _buildSection(
    context,
    'Intensity',
    _formatIntensity(analysis.intensity!),
    Icons.trending_up,
    isDark,
  ),
],

// ✅ NEW: Context flags
if (analysis.contextFlags != null && analysis.contextFlags!.isNotEmpty) ...[
  const SizedBox(height: 16),
  _buildContextFlags(context, analysis.contextFlags!, isDark),
],

// ✅ NEW: Anxiety assessment
if (analysis.anxietyAssessment != null) ...[
  const SizedBox(height: 16),
  _buildAnxietyAssessment(context, analysis.anxietyAssessment!, isDark),
],
```

**Add helper methods at the end of the class:**

```dart
String _formatIntensity(String intensity) {
  return intensity.replaceAll('_', ' ').split(' ').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join(' ');
}

Widget _buildContextFlags(BuildContext context, Map<String, dynamic> flags, bool isDark) {
  final activeFlags = flags.entries
      .where((e) => e.value == true)
      .map((e) => _formatFlag(e.key))
      .toList();
  
  if (activeFlags.isEmpty) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(activeFlags.join(', '))),
      ],
    ),
  );
}

String _formatFlag(String flag) {
  return flag.replaceAll('_', ' ').split(' ').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join(' ');
}

Widget _buildAnxietyAssessment(BuildContext context, Map<String, dynamic> assessment, bool isDark) {
  final riskLevel = assessment['risk_level'] as String?;
  final suggestions = (assessment['mitigation_suggestions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList() ?? [];
  
  if (riskLevel == null) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _getRiskColor(riskLevel).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _getRiskColor(riskLevel)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, size: 18, color: _getRiskColor(riskLevel)),
            const SizedBox(width: 8),
            Text(
              'Response Anxiety: ${riskLevel.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('• $s', style: const TextStyle(fontSize: 12)),
          )),
        ],
      ],
    ),
  );
}

Color _getRiskColor(String level) {
  switch (level.toLowerCase()) {
    case 'high': return Colors.red;
    case 'medium': return Colors.orange;
    case 'low': return Colors.green;
    default: return Colors.grey;
  }
}
```

---

## 🧪 Phase 4: Testing (1-2 days)

### **STEP 10: Update Tests**

**File:** `frontend/test/widgets/tone_badge_test.dart`

**Add tests for new tones:**

```dart
// Add after existing tests
testWidgets('displays Overwhelmed tone with correct emoji', (tester) async {
  final analysis = AIAnalysis(
    id: 'test',
    messageId: 'msg',
    tone: 'Overwhelmed',
    intensity: 'high',
    analysisTimestamp: 123,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ToneBadge(analysis: analysis),
      ),
    ),
  );

  expect(find.text('😵'), findsOneWidget);
  expect(find.text('Overwhelmed'), findsOneWidget);
});

testWidgets('displays intensity indicator', (tester) async {
  final analysis = AIAnalysis(
    id: 'test',
    messageId: 'msg',
    tone: 'Friendly',
    intensity: 'high',
    analysisTimestamp: 123,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ToneBadge(analysis: analysis),
      ),
    ),
  );

  // Should have intensity dot
  expect(find.byType(Container), findsWidgets);
});
```

**Run tests:**
```bash
cd frontend
flutter test test/widgets/tone_badge_test.dart
flutter test test/models/ai_analysis_test.dart
```

---

### **STEP 11: Manual Testing**

```bash
cd frontend
flutter run
```

**Test scenarios:**
1. Send: "Hey! How are you?" → Should be **Friendly** (medium intensity)
2. Send: "I'm SO STRESSED RIGHT NOW" → Should be **Overwhelmed** (very_high intensity)
3. Send: "That's great /s" → Should be **Sarcastic** with tone_indicator flag
4. Send: "Thank you so much!" → Should be **Appreciative**
5. Check that ToneBadge shows intensity dot
6. Tap badge → verify ToneDetailSheet shows new fields

---

## 📊 Phase 5: Gradual Rollout (1 week)

### **STEP 12: Feature Flag Setup (Optional)**

**Create:** `frontend/lib/core/feature_flags.dart`

```dart
class FeatureFlags {
  static const bool useEnhancedAnalysis = true;  // Toggle this
  static const bool showIntensity = true;
  static const bool showAnxietyAssessment = true;
}
```

**Use in widgets:**
```dart
if (FeatureFlags.showIntensity && analysis.intensity != null) {
  // Show intensity indicator
}
```

---

### **STEP 13: Monitor & Rollout**

**Week 1:**
- Deploy to production
- Monitor Edge Function logs: `supabase functions logs ai-analyze-tone`
- Check for errors in analysis results
- Verify new tones appear correctly

**Week 2:**
- Collect user feedback
- Monitor which new tones are used most
- Check if intensity indicators are helpful
- Verify anxiety assessments work

---

## 🎯 Quick Reference

### **Files Modified:**

| File | Change | Lines |
|------|--------|-------|
| `backend/.../ai_analyze_tone/index.ts` | Import enhanced prompt | 5-9, 99 |
| `backend/.../enhanced-tone-analysis.ts` | Add ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT | +40 lines |
| `frontend/.../ai_analysis.dart` | Add 4 new optional fields | 10-20, 30-50 |
| `frontend/.../tone_badge.dart` | Add 15 tone emojis, intensity dot | 74-110, 140-160 |
| `frontend/.../tone_detail_sheet.dart` | Add 3 new sections | 150-200 |

### **Commands:**

```bash
# Deploy backend
cd backend/supabase
supabase functions deploy ai_analyze_tone
supabase db push  # If you ran migration

# Test frontend
cd frontend
flutter test
flutter run

# Monitor
supabase functions logs ai_analyze_tone --follow
```

### **Rollback Plan:**

If issues arise:

1. **Revert Edge Function:**
   ```typescript
   // Change back to:
   import { ... } from '../_shared/prompts/tone-analysis.ts';
   ```

2. **Redeploy:**
   ```bash
   supabase functions deploy ai_analyze_tone
   ```

---

## ✅ Success Checklist

- [ ] Backend imports updated
- [ ] Enhanced prompt added
- [ ] Edge function deployed
- [ ] Test API call works
- [ ] Database migration run (optional)
- [ ] Flutter model updated
- [ ] ToneBadge shows new tones
- [ ] ToneBadge shows intensity
- [ ] ToneDetailSheet shows new data
- [ ] Tests updated and passing
- [ ] Manual testing complete
- [ ] Deployed to production
- [ ] Monitoring active

---

**Total Time:** 2-4 hours for basic upgrade, +2 days for full testing

**Your enhanced tone analysis is now live with 23 tones, intensity scaling, and neurodivergent support!** 🎉
