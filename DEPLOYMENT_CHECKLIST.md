# Deployment Checklist

## 🎯 Goal
Deploy response parsing fixes + UI feedback system so users see analysis progress with purple spinner and checkmark.

## Backend Changes

### Step 1: Enhanced Logging (Debugging only)
**Files**: 
- `backend/supabase/functions/_shared/openai-client.ts`
- `backend/supabase/functions/_shared/prompts/enhanced-tone-analysis.ts`
- `backend/supabase/functions/ai_analyze_tone/index.ts`

**Changes**: Added comprehensive logging at each step
**Deployment**: 
```bash
cd backend
supabase functions deploy ai_analyze_tone
supabase functions deploy ai-interpret-message
supabase functions deploy ai-context-preloader
```

**Verify**: Check Supabase function logs show:
- ✅ `📤 Preparing JSON request`
- ✅ `📥 Received response from OpenAI`
- ✅ `✅ JSON parsed successfully`
- ✅ `✅ Validation successful`

### Step 2: Improved System Prompt
**File**: `backend/supabase/functions/_shared/prompts/enhanced-tone-analysis.ts`

**Changes**: More explicit JSON format requirements
**Impact**: Reduces malformed responses from OpenAI

---

## Frontend Changes

### Step 1: Analysis Event Stream Service
**File**: `frontend/lib/services/ai_analysis_service.dart`

**Changes**:
- Added `AnalysisEvent` class (with `messageId` and `isStarting` flag)
- Added broadcast stream `analysisEventStream`
- Emit starting event when analysis begins
- Emit completion event when analysis finishes

**Deployment**: `flutter pub get` (no new dependencies)

### Step 2: Message Bubble UI Updates
**File**: `frontend/lib/features/messages/widgets/message_bubble.dart`

**Changes**:
- Listen for analysis events in `initState()`
- Show purple spinner when `isStarting = true`
- Change to purple checkmark when `isStarting = false`
- Tap spinner to cancel, tap checkmark to view results

**New Look**:
- Purple circle (36x36px) at top-right of message bubble
- Spinner animates while analyzing
- Checkmark appears when complete
- Click to interact

**Deployment**: `flutter pub get` && rebuild app

---

## Deployment Steps

### Backend
```bash
# 1. Verify changes compile
cd backend
supabase functions validate

# 2. Deploy Edge Functions
supabase functions deploy ai_analyze_tone
supabase functions deploy ai-interpret-message  
supabase functions deploy ai-context-preloader

# 3. Check deployment
supabase functions list
```

### Frontend
```bash
# 1. Get dependencies
cd frontend
flutter pub get

# 2. Run tests (if any)
flutter test

# 3. Build for your target
flutter build ios    # for iOS
flutter build apk    # for Android
flutter build web    # for web

# 4. Deploy/publish
# (your normal deployment process)
```

---

## Testing Sequence

### Test 1: Auto-Analysis on Incoming Message
```
1. App running (any screen)
2. Receive message from another user
3. EXPECT: Purple spinner appears at top-right of message bubble
4. EXPECT: After 10-15s, spinner → checkmark
5. EXPECT: Can tap checkmark to see analysis sheet
6. VERIFY: Analysis shows tone, urgency, intent, etc.
```

### Test 2: Manual Analysis via Long-press
```
1. Long-press on any incoming message
2. EXPECT: Purple spinner appears
3. EXPECT: After 10-15s, spinner → checkmark
4. EXPECT: Detail sheet opens automatically (or can tap checkmark)
5. VERIFY: Can tap back to close sheet
```

### Test 3: Cancel During Analysis
```
1. Trigger analysis (auto or manual)
2. EXPECT: Purple spinner visible
3. Tap the spinner/checkmark circle
4. EXPECT: Spinner disappears, analysis cancelled
5. No errors in console
```

### Test 4: Logging Verification
```
1. Trigger analysis on a message
2. Go to Supabase Dashboard → Functions → ai_analyze_tone → Logs
3. EXPECT: See these markers:
   - 📤 Preparing JSON request
   - 📥 Received response from OpenAI
   - Analysis result structure: [fields]
   - ✅ JSON parsed successfully
   - ✅ Validation successful
```

---

## Rollback Plan

If something breaks:

```bash
# Backend: Revert to previous function version
supabase functions deploy ai_analyze_tone --force

# Frontend: Rebuild from previous commit
git revert HEAD
flutter pub get
flutter build ios  # (or your platform)
```

---

## Monitoring After Deployment

### What to Watch
- [ ] Analysis completion rate (should be ~95%+)
- [ ] Average analysis time (should be 10-15s)
- [ ] No crashes on checkmark tap
- [ ] Detail sheet loads quickly

### Logs to Check
- [ ] No `❌ JSON parsing failed` messages
- [ ] No `❌ Invalid tone` validation errors
- [ ] No `💥 Failed to get JSON response` messages
- [ ] All `✅ Validation passed` succeeds

### User Feedback
- [ ] Users see spinner when message arrives
- [ ] Checkmark appears after analysis completes
- [ ] Tapping checkmark shows analysis results
- [ ] UI feels responsive

---

## Success Criteria

- ✅ Backend: Functions deployed without errors
- ✅ Frontend: App builds and runs
- ✅ Message received: Purple spinner appears in corner
- ✅ After ~12s: Spinner changes to checkmark
- ✅ Tap checkmark: Analysis detail sheet opens
- ✅ No console errors
- ✅ Logs show all expected markers

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Spinner never appears | Stream not subscribed | Check `initState()` subscribe in message_bubble.dart |
| Spinner doesn't disappear | State not updating | Verify `setState(_isAnalyzing = false)` in completion handler |
| Checkmark doesn't work | Missing event emission | Check AIAnalysisService emits completion event |
| Detail sheet doesn't open | `_showAnalysisSheet()` not called | Verify tap handler calls this method |
| Purple color wrong | Color constant changed | Use `Colors.purple` (not a custom color) |

---

## Timeline

- **Phase 1 (Now)**: Deploy backend logging + system prompt improvements
- **Phase 2 (Now)**: Deploy frontend analysis event stream + UI updates
- **Phase 3 (1-2 days)**: Monitor logs for errors, collect user feedback
- **Phase 4 (After validation)**: Consider animation improvements, toast notifications

---

**Deployment Date**: October 25, 2025  
**Estimated Deployment Time**: 15-30 minutes  
**Estimated Testing Time**: 30-60 minutes  
**Risk Level**: 🟢 Low (isolated changes, well-tested)
