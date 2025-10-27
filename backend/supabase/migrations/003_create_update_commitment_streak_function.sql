-- Create function to update commitment streaks
CREATE OR REPLACE FUNCTION update_commitment_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_completed_today INTEGER;
  v_total_completed INTEGER;
  v_total_commitments INTEGER;
  v_current_streak INTEGER;
  v_best_streak INTEGER;
  v_completion_rate DECIMAL;
BEGIN
  -- Get total completed action items for this user
  SELECT COUNT(*)
  INTO v_total_completed
  FROM public.action_items
  WHERE user_id = p_user_id AND status = 'completed';
  
  -- Get total action items for this user
  SELECT COUNT(*)
  INTO v_total_commitments
  FROM public.action_items
  WHERE user_id = p_user_id;
  
  -- Calculate completion rate
  v_completion_rate := CASE 
    WHEN v_total_commitments = 0 THEN 0.0
    ELSE ROUND((v_total_completed::DECIMAL / v_total_commitments) * 100, 2)
  END;
  
  -- Calculate current streak (consecutive days with completed items)
  WITH consecutive_days AS (
    SELECT 
      DATE(to_timestamp(status_updated_at))::DATE as completion_date,
      ROW_NUMBER() OVER (
        ORDER BY DATE(to_timestamp(status_updated_at))::DATE
      ) - ROW_NUMBER() OVER (
        ORDER BY DATE(to_timestamp(status_updated_at))::DATE
      ) as grp
    FROM public.action_items
    WHERE user_id = p_user_id 
      AND status = 'completed'
      AND status_updated_at IS NOT NULL
    GROUP BY DATE(to_timestamp(status_updated_at))::DATE
  )
  SELECT COUNT(*)
  INTO v_current_streak
  FROM (
    SELECT * FROM consecutive_days
    ORDER BY completion_date DESC
    LIMIT (
      SELECT COUNT(*) FROM consecutive_days 
      WHERE grp = (SELECT grp FROM consecutive_days ORDER BY completion_date DESC LIMIT 1)
    )
  ) sq;
  
  -- Get best streak (placeholder - could be enhanced)
  v_best_streak := GREATEST(v_current_streak, COALESCE((
    SELECT best_streak_count FROM public.commitment_streaks WHERE user_id = p_user_id
  ), 0));
  
  -- Update or create commitment streak record
  INSERT INTO public.commitment_streaks (
    user_id,
    current_streak_count,
    best_streak_count,
    total_completed,
    total_commitments,
    completion_rate,
    last_completion_at
  ) VALUES (
    p_user_id,
    v_current_streak,
    v_best_streak,
    v_total_completed,
    v_total_commitments,
    v_completion_rate,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    current_streak_count = v_current_streak,
    best_streak_count = v_best_streak,
    total_completed = v_total_completed,
    total_commitments = v_total_commitments,
    completion_rate = v_completion_rate,
    last_completion_at = NOW(),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create a trigger to update streaks when action items are updated
CREATE OR REPLACE FUNCTION trigger_update_streak()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    PERFORM update_commitment_streak(NEW.user_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on action_items table
DROP TRIGGER IF EXISTS action_items_update_streak ON public.action_items;
CREATE TRIGGER action_items_update_streak
AFTER UPDATE ON public.action_items
FOR EACH ROW
WHEN (NEW.status IS DISTINCT FROM OLD.status)
EXECUTE FUNCTION trigger_update_streak();
