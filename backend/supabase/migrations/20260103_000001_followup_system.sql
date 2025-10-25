-- ============================================================
-- SMART FOLLOW-UP SYSTEM
-- ============================================================

-- Follow-up items (things that need response)
CREATE TABLE follow_up_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  
  -- Item details
  item_type TEXT NOT NULL CHECK (item_type IN (
    'action_item',      -- "I'll send you..."
    'unanswered_question', -- Question without response
    'pending_response',    -- Conversation waiting for reply
    'scheduled_followup'   -- User-scheduled reminder
  )),
  
  title TEXT NOT NULL,
  description TEXT,
  extracted_text TEXT, -- Original text that triggered this
  
  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',
    'completed',
    'dismissed',
    'snoozed'
  )),
  
  -- Priority
  priority INTEGER DEFAULT 50 CHECK (priority >= 0 AND priority <= 100),
  
  -- Timing
  detected_at INTEGER NOT NULL,
  due_at INTEGER, -- When action should be completed
  remind_at INTEGER, -- When to remind user
  snoozed_until INTEGER, -- If snoozed
  completed_at INTEGER,
  
  -- Context triggers
  triggers JSONB, -- { "app": "email", "calendar_event": "meeting", "location": "office" }
  
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  
  UNIQUE(user_id, message_id, item_type)
);

CREATE INDEX idx_followup_items_user ON follow_up_items(user_id);
CREATE INDEX idx_followup_items_status ON follow_up_items(status);
CREATE INDEX idx_followup_items_remind_at ON follow_up_items(remind_at);
CREATE INDEX idx_followup_items_conversation ON follow_up_items(conversation_id);

-- Action items (specific commitments)
CREATE TABLE action_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follow_up_item_id UUID NOT NULL REFERENCES follow_up_items(id) ON DELETE CASCADE,
  
  -- Action details
  action_type TEXT NOT NULL, -- send, call, meet, review, decide, etc.
  action_target TEXT, -- What/who is the action about
  commitment_text TEXT NOT NULL, -- Original promise
  
  -- Extracted details
  mentioned_deadline TEXT, -- "this afternoon", "by Friday"
  extracted_deadline INTEGER, -- Parsed timestamp
  
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_action_items_followup ON action_items(follow_up_item_id);

-- Unanswered questions
CREATE TABLE unanswered_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follow_up_item_id UUID NOT NULL REFERENCES follow_up_items(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  
  -- Question details
  question_text TEXT NOT NULL,
  question_type TEXT, -- when, where, what, who, why, how, yes/no
  context TEXT, -- Surrounding context
  
  -- Timing
  asked_at INTEGER NOT NULL,
  time_since_asked INTEGER, -- In seconds
  
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_unanswered_questions_followup ON unanswered_questions(follow_up_item_id);
CREATE INDEX idx_unanswered_questions_message ON unanswered_questions(message_id);

-- Context triggers (app usage, calendar, location)
CREATE TABLE context_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  follow_up_item_id UUID NOT NULL REFERENCES follow_up_items(id) ON DELETE CASCADE,
  
  -- Trigger details
  trigger_type TEXT NOT NULL CHECK (trigger_type IN (
    'app_opened',       -- When user opens specific app
    'calendar_event',   -- Before/during calendar event
    'location',         -- When at specific location
    'time_of_day',      -- Specific time
    'day_of_week'       -- Specific day
  )),
  
  trigger_config JSONB NOT NULL, -- Configuration for trigger
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_triggered INTEGER,
  trigger_count INTEGER DEFAULT 0,
  
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_context_triggers_user ON context_triggers(user_id);
CREATE INDEX idx_context_triggers_active ON context_triggers(is_active);
CREATE INDEX idx_context_triggers_followup ON context_triggers(follow_up_item_id);

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Get pending follow-ups for user
CREATE OR REPLACE FUNCTION get_pending_followups(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  item_id UUID,
  conversation_id UUID,
  item_type TEXT,
  title TEXT,
  description TEXT,
  priority INTEGER,
  detected_at INTEGER,
  remind_at INTEGER,
  triggers JSONB
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fi.id AS item_id,
    fi.conversation_id,
    fi.item_type,
    fi.title,
    fi.description,
    fi.priority,
    fi.detected_at,
    fi.remind_at,
    fi.triggers
  FROM follow_up_items fi
  WHERE fi.user_id = p_user_id
    AND fi.status = 'pending'
    AND (fi.snoozed_until IS NULL OR fi.snoozed_until < EXTRACT(EPOCH FROM NOW())::INTEGER)
  ORDER BY fi.priority DESC, fi.detected_at ASC
  LIMIT p_limit;
END;
$$;

-- Get follow-ups for specific conversation
CREATE OR REPLACE FUNCTION get_conversation_followups(
  p_user_id UUID,
  p_conversation_id UUID
)
RETURNS TABLE (
  item_id UUID,
  item_type TEXT,
  title TEXT,
  description TEXT,
  priority INTEGER,
  status TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fi.id AS item_id,
    fi.item_type,
    fi.title,
    fi.description,
    fi.priority,
    fi.status
  FROM follow_up_items fi
  WHERE fi.user_id = p_user_id
    AND fi.conversation_id = p_conversation_id
    AND fi.status IN ('pending', 'snoozed')
  ORDER BY fi.priority DESC, fi.detected_at DESC;
END;
$$;

-- Mark follow-up as completed
CREATE OR REPLACE FUNCTION complete_followup(
  p_user_id UUID,
  p_item_id UUID
)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_now INTEGER;
BEGIN
  v_now := EXTRACT(EPOCH FROM NOW())::INTEGER;
  
  UPDATE follow_up_items
  SET 
    status = 'completed',
    completed_at = v_now,
    updated_at = v_now
  WHERE id = p_item_id AND user_id = p_user_id;
END;
$$;

-- Snooze follow-up
CREATE OR REPLACE FUNCTION snooze_followup(
  p_user_id UUID,
  p_item_id UUID,
  p_snooze_duration INTEGER -- In seconds
)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_now INTEGER;
BEGIN
  v_now := EXTRACT(EPOCH FROM NOW())::INTEGER;
  
  UPDATE follow_up_items
  SET 
    status = 'snoozed',
    snoozed_until = v_now + p_snooze_duration,
    updated_at = v_now
  WHERE id = p_item_id AND user_id = p_user_id;
END;
$$;

