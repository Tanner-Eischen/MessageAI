# Offline Message Queueing Test Documentation

## Overview
The MessageAI app implements offline-first message queueing using Drift (local SQLite database) and Supabase. Messages are saved locally first and then synced to the backend when connectivity is available.

## Architecture

### Components
1. **Local Database (Drift)**
   - `Messages` table - stores all messages with `isSynced` flag
   - `PendingOutbox` table - queue for operations that need to be synced

2. **Message Service**
   - Located: `frontend/lib/services/message_service.dart`
   - Implements optimistic updates
   - Automatically queues messages for sync

3. **Send Queue**
   - Located: `frontend/lib/state/send_queue.dart`
   - Manages background synchronization
   - Retries failed operations

## How It Works

### 1. Sending a Message (Offline or Online)

```dart
// User sends a message
await messageService.sendMessage(
  conversationId: conversationId,
  body: "Hello, World!",
);
```

**What happens:**
1. Message is immediately saved to local database with `isSynced: false`
2. Message appears in UI instantly (optimistic update)
3. System attempts to sync to Supabase backend
4. If sync succeeds:
   - Message marked as `isSynced: true`
   - Removed from PendingOutbox
5. If sync fails (offline/network error):
   - Message remains in local database with `isSynced: false`
   - Operation stays in PendingOutbox for retry
   - UI shows message with "pending" indicator

### 2. Message Sync Process

The sync process happens automatically:

```dart
// Background sync (automatic)
await messageRepo.syncUnsyncedMessages();
```

This process:
- Queries all messages where `isSynced = false`
- Attempts to send each to the backend
- Marks successful sends as synced
- Leaves failed sends for next retry

### 3. Retry Mechanism

The `PendingOutbox` table tracks:
- `operation` - type of operation (e.g., "send_message")
- `payload` - serialized operation data
- `retryCount` - number of retry attempts
- `lastError` - last error message

Maximum retries: 3 (configurable in `PendingOutboxDao`)

## Manual Testing Procedure

### Test 1: Send Message While Online

1. Start the app with internet connection
2. Open a conversation
3. Send a message
4. **Expected:** Message appears immediately with a checkmark (synced)

### Test 2: Send Message While Offline

1. Disable network connectivity:
   - Android: Enable Airplane mode
   - iOS: Disable WiFi and Cellular
   - Desktop/Web: Disconnect network
2. Open a conversation
3. Send a message
4. **Expected:** 
   - Message appears immediately in UI
   - Message shows "pending" indicator (clock icon)
5. Re-enable network connectivity
6. Wait 2-3 seconds for automatic sync
7. **Expected:**
   - Message indicator changes to checkmark
   - Message successfully synced to server

### Test 3: Multiple Messages Offline

1. Disable network connectivity
2. Send 5 messages in a row
3. **Expected:** All messages appear in UI with "pending" indicators
4. Re-enable network connectivity
5. **Expected:** All messages sync in order and show checkmarks

### Test 4: Image Upload Offline

1. Disable network connectivity
2. Select an image to send
3. **Expected:** Image upload fails gracefully with error message
4. Message with text can still be queued

**Note:** Image uploads require connectivity as they need to be uploaded to storage first before message can be created.

### Test 5: Verify Persistence

1. Send message while offline
2. Close the app completely
3. Reopen the app (still offline)
4. **Expected:** Unsent message still visible with "pending" indicator
5. Enable connectivity
6. **Expected:** Message syncs automatically

## Database Queries for Verification

### Check Unsynced Messages
```sql
SELECT * FROM messages WHERE is_synced = 0;
```

### Check Pending Operations
```sql
SELECT * FROM pending_outbox ORDER BY created_at;
```

### Check Retry Count
```sql
SELECT id, operation, retry_count, last_error 
FROM pending_outbox 
WHERE retry_count > 0;
```

## Code Locations

### Core Implementation Files

1. **Message Service**
   - `frontend/lib/services/message_service.dart`
   - Handles message sending with local-first approach

2. **Send Queue**
   - `frontend/lib/state/send_queue.dart`
   - Manages synchronization and retries

3. **Message Repository**
   - `frontend/lib/data/repositories/message_repository.dart`
   - Coordinates between local DB and API

4. **Pending Outbox DAO**
   - `frontend/lib/data/drift/daos/pending_outbox_dao.dart`
   - Database operations for pending queue

5. **Message DAO**
   - `frontend/lib/data/drift/daos/message_dao.dart`
   - Database operations for messages

## UI Indicators

The message screen shows different states:

- **Sending:** CircularProgressIndicator
- **Pending/Queued:** Clock icon (⏰)
- **Synced:** Checkmark icon (✓)
- **Failed:** Retry option on long press (if applicable)

## Limitations

1. **Image Uploads:** Require connectivity to upload to storage bucket first
2. **Max Retries:** Operations fail after 3 retry attempts
3. **Storage:** Limited by device storage capacity
4. **Cleanup:** Old failed operations (>7 days) should be manually cleaned

## Future Enhancements

1. Add background sync service (WorkManager/background tasks)
2. Show pending count in conversation list
3. Add manual retry button for failed messages
4. Implement exponential backoff for retries
5. Add conflict resolution for concurrent edits
6. Support for offline media upload queueing

## Testing Checklist

- [x] Message appears instantly when sent offline
- [x] Message syncs when connectivity restored
- [x] Multiple offline messages sync in order
- [x] App restart preserves unsent messages
- [x] UI shows correct sync status indicators
- [x] Failed syncs can be retried
- [ ] Stress test: 100+ offline messages
- [ ] Network interruption during sync
- [ ] Concurrent message sends from multiple devices

## Verification Completed

Date: 2025-10-22
Status: ✅ Offline queueing implementation verified

The offline message queueing feature is **fully implemented and functional**. The system uses:
- Local-first architecture with Drift database
- Optimistic UI updates
- Automatic background synchronization
- Retry mechanism with pending queue
- Clear UI indicators for sync status

All core functionality is working as expected!

