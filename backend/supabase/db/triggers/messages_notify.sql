-- Trigger: messages_notify
-- Broadcasts realtime event when a message is inserted
-- Usage: Subscribe to `realtime:messages` channel to receive events

-- Create function to broadcast message events
CREATE OR REPLACE FUNCTION public.messages_notify()
RETURNS trigger AS $$
BEGIN
  -- Perform the realtime broadcast
  PERFORM pg_notify(
    'realtime:messages',
    json_build_object(
      'type', TG_OP,
      'record', row_to_json(NEW),
      'schema', TG_TABLE_SCHEMA,
      'table', TG_TABLE_NAME,
      'timestamp', now()
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT events on messages table
DROP TRIGGER IF EXISTS messages_notify_insert ON messages;
CREATE TRIGGER messages_notify_insert
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION public.messages_notify();

-- Create trigger for UPDATE events on messages table
DROP TRIGGER IF EXISTS messages_notify_update ON messages;
CREATE TRIGGER messages_notify_update
  AFTER UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION public.messages_notify();
