-- Trigger: receipts_notify
-- Broadcasts realtime event when a message receipt is inserted
-- Usage: Subscribe to `realtime:receipts` channel to receive events

-- Create function to broadcast receipt events
CREATE OR REPLACE FUNCTION public.receipts_notify()
RETURNS trigger AS $$
BEGIN
  -- Perform the realtime broadcast
  PERFORM pg_notify(
    'realtime:receipts',
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

-- Create trigger for INSERT events on message_receipts table
DROP TRIGGER IF EXISTS receipts_notify_insert ON message_receipts;
CREATE TRIGGER receipts_notify_insert
  AFTER INSERT ON message_receipts
  FOR EACH ROW
  EXECUTE FUNCTION public.receipts_notify();

-- Create trigger for UPDATE events on message_receipts table
DROP TRIGGER IF EXISTS receipts_notify_update ON message_receipts;
CREATE TRIGGER receipts_notify_update
  AFTER UPDATE ON message_receipts
  FOR EACH ROW
  EXECUTE FUNCTION public.receipts_notify();
