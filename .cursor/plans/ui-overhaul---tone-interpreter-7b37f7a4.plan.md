<!-- 7b37f7a4-3027-4e7b-9964-6637b59b8d85 21469e5d-48e5-4034-9f64-a4f84a3ddc1c -->
# UI Overhaul + Tone Interpreter Implementation

## Architecture Vision

The message screen becomes a layered interface:

- **Background Layer**: AI insights, tone analysis, suggestions (always present)
- **Foreground Layer**: Message list in a sliding panel that slides up/down
- **Default State**: Message panel slides up (80% height), showing peek of AI content
- **AI View**: User swipes down to reveal full AI analysis behind messages

## Phase 1: Theme System Overhaul

### Update Theme to Black/White Minimal

- Replace burnt orange theme with monochrome palette
- Use `theme_guide.md` as reference but implement black/white/gray only
- Accent colors only for critical actions (send button, online status)
- Remove all color gradients, use sharp shadows and clean lines

**Files to modify:**

- `frontend/lib/app.dart` - Replace entire `ThemeData` configuration
  - Light theme: White backgrounds (#FFFFFF), black text (#000000), gray surfaces (#F5F5F5)
  - Dark theme: True black backgrounds (#000000), white text (#FFFFFF), dark gray surfaces (#1A1A1A)
  - Minimal accent: Single green for online, single blue for actions

### Update existing screens with new theme

- `frontend/lib/features/conversations/screens/conversations_list_screen.dart`
  - Cleaner list items, sharper dividers
  - Remove colored avatars, use monochrome initials
  - Flat design with subtle shadows

- `frontend/lib/features/auth/screens/auth_screen.dart`
  - Minimal input fields with black borders
  - Clean button design

- `frontend/lib/features/settings/screens/settings_screen.dart`
  - Flat list design matching new aesthetic

### Create shared theme constants

**New file:** `frontend/lib/core/theme/app_theme.dart`

- Define color constants from theme guide (Gray scale only)
- Typography system (sizes, weights)
- Spacing constants
- Border radius constants
- Shadow definitions

## Phase 2: Sliding Panel Architecture

### Build sliding panel widget system

**New file:** `frontend/lib/widgets/sliding_panel.dart`

- `SlidingPanel` widget using `DraggableScrollableSheet`
- Min height: 0.2 (20% - peek view)
- Max height: 0.95 (95% - nearly full screen)
- Initial height: 0.8 (80% - standard messaging view)
- Snap positions at 0.2, 0.5, 0.8, 0.95
- Smooth animations with custom curves
- Handle decorations: Rounded top corners, drag handle indicator

### Redesign Message Screen with layers

**Modify:** `frontend/lib/features/messages/screens/message_screen.dart`

- Restructure layout:
  ```dart
  Stack(
    children: [
      // Background: AI Insights Panel
      _buildAIInsightsBackground(),
      
      // Foreground: Sliding Message Panel
      SlidingPanel(
        child: MessageListView(),
        onSlide: (position) => setState(() => _panelPosition = position),
      ),
    ],
  )
  ```

- Extract message list into separate widget
- Create AI background placeholder (will populate with tone analysis)

**New file:** `frontend/lib/features/messages/widgets/message_list_panel.dart`

- Extract current message list building logic
- Include compose bar at bottom of panel
- Maintain all existing functionality (typing indicators, receipts, etc.)

**New file:** `frontend/lib/features/messages/widgets/ai_insights_background.dart`

- Background container for AI features
- Initially shows: "Pull down to see AI insights"
- Will display tone analysis when implemented

## Phase 3: Tone Interpreter Backend

### Database Schema

**New file:** `backend/supabase/migrations/20251024_000002_ai_analysis.sql`

```sql
CREATE TABLE message_ai_analysis (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  tone TEXT NOT NULL,
  urgency_level TEXT,
  intent TEXT,
  confidence_score FLOAT,
  analysis_timestamp BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_analysis_message ON message_ai_analysis(message_id);
CREATE INDEX idx_ai_analysis_timestamp ON message_ai_analysis(analysis_timestamp);
```

### Anthropic Client Setup

**New file:** `backend/supabase/functions/_shared/anthropic-client.ts`

- Wrapper for Anthropic API using Claude Sonnet 4
- Type-safe message formatting
- Error handling and retries
- Rate limiting considerations

**New file:** `backend/supabase/functions/_shared/prompts/tone-analysis.ts`

- Prompt engineering for tone detection
- System prompt defining tone categories
- Context inclusion strategy
- JSON response formatting

### Edge Function for Analysis

**New file:** `backend/supabase/functions/ai_analyze_tone/index.ts`

- Accept: `{ message_id, message_body, conversation_context? }`
- Call Anthropic API with message + context
- Parse response into structured data
- Store analysis in `message_ai_analysis` table
- Return: `{ tone, urgency_level, intent, confidence_score }`

Tone categories:

- Friendly, Professional, Urgent, Casual, Formal, Concerned, Excited, Neutral

Urgency levels:

- Low, Medium, High, Critical

**Modify:** `backend/supabase/config.toml`

- Add new Edge Function configuration
- Set environment variables for Anthropic API key

### RPC Function for Bulk Analysis

**Add to migration:** `backend/supabase/migrations/20251024_000002_ai_analysis.sql`

```sql
CREATE OR REPLACE FUNCTION get_conversation_ai_analysis(p_conversation_id UUID)
RETURNS TABLE (
  message_id UUID,
  tone TEXT,
  urgency_level TEXT,
  intent TEXT,
  confidence_score FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT a.message_id, a.tone, a.urgency_level, a.intent, a.confidence_score
  FROM message_ai_analysis a
  JOIN messages m ON a.message_id = m.id
  WHERE m.conversation_id = p_conversation_id
  ORDER BY m.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Phase 4: Tone Interpreter Frontend (Remote-Only, No Local Cache)

### AI Service Layer - Simplified

**New file:** `frontend/lib/services/ai_analysis_service.dart`

- Request analysis for a message (calls Edge Function)
- Fetch analysis directly from Supabase (no local cache)
- Debounce requests to avoid spam
- Simple in-memory caching for current session only
- Returns data directly from API calls

### State Management

**New file:** `frontend/lib/state/ai_providers.dart`

```dart
// Provider for conversation-wide AI analysis
final conversationAIAnalysisProvider = FutureProvider.family<Map<String, AIAnalysis>, String>(
  (ref, conversationId) async {
    final service = AIAnalysisService();
    return await service.getConversationAnalysis(conversationId);
  },
);

// Provider for triggering analysis
final requestAnalysisProvider = Provider((ref) => AIAnalysisService());
```

### UI Components for Tone Display

**New file:** `frontend/lib/features/messages/widgets/tone_badge.dart`

- Small badge showing tone emoji + label
- Color coding: Urgent=red, Professional=blue, Friendly=green, etc.
- Tap to expand details
- Position: Bottom-right of message bubble (subtle, non-intrusive)

**New file:** `frontend/lib/features/messages/widgets/ai_insights_panel.dart`

- Replaces `ai_insights_background.dart` placeholder
- Shows conversation-level insights:
  - Overall tone of conversation
  - Most recent message analysis
  - Urgency indicators
  - Detected intents
- Visual design: Cards with minimal shadows, clean typography
- "Analyze Message" button for manual triggers

**Modify:** `frontend/lib/features/messages/widgets/message_list_panel.dart`

- Add tone badges to message bubbles
- Wire up tap handlers to show detail sheet

**New file:** `frontend/lib/features/messages/widgets/tone_detail_sheet.dart`

- Bottom sheet showing full analysis
- Display: Tone, urgency, intent, confidence score
- Feedback mechanism: "Was this helpful?" thumbs up/down
- Future: User corrections to improve model

### Integration with Message Flow

**Modify:** `frontend/lib/services/message_service.dart`

- After sending message, trigger tone analysis asynchronously
- Don't block message send on analysis
- Store message ID for later analysis result

**Modify:** `frontend/lib/features/messages/screens/message_screen.dart`

- Pass AI analysis data to `AIInsightsPanel`
- Show loading state while analysis pending
- Update UI when analysis completes via Riverpod listener

## Phase 5: Polish & Testing

### Update Documentation

- Update `theme_guide.md` with implemented black/white palette
- Update `technical_implementation (1).md` with completed PR #1-2
- Add comments explaining sliding panel architecture

### Settings Integration

**Modify:** `frontend/lib/features/settings/screens/settings_screen.dart`

- Add "AI Features" section
- Toggle: Enable/disable tone analysis
- Option: Auto-analyze all messages vs manual trigger
- Privacy notice about AI processing

### Testing Checklist

- Sliding panel smooth on various devices
- Tone analysis works for different message types
- Theme consistent across light/dark modes
- No performance issues with analysis
- Graceful error handling when API fails
- Works offline (shows cached analysis only)

## Implementation Order

1. Theme system first (provides foundation)
2. Sliding panel architecture (core UX pattern)
3. Backend tone analysis (can test independently)
4. Frontend AI display (brings it all together)
5. Integration and polish

### To-dos

- [ ] Create black/white theme system and update app.dart with new ThemeData
- [ ] Update existing screens (conversations list, auth, settings) with minimal design
- [ ] Build SlidingPanel widget with DraggableScrollableSheet
- [ ] Restructure message screen with Stack layout (background + sliding panel)
- [ ] Create migration for message_ai_analysis table
- [ ] Create Anthropic client wrapper and tone analysis prompts
- [ ] Implement ai_analyze_tone Edge Function
- [ ] Add ai_analysis Drift table and DAO
- [ ] Create AIAnalysisService and state providers
- [ ] Build tone badge, insights panel, and detail sheet widgets
- [ ] Wire up message flow with AI analysis and test end-to-end
- [ ] Add AI settings toggles and update documentation