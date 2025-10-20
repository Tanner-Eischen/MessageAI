# Phase 04 — Optimistic Send & Realtime

**Branch:** `feat/optimistic-realtime`  
**PR:** `[A] Phase 04 — optimistic send + realtime`

## Tasks
- [ ] Files: `state/realtime_providers.dart`, `state/send_queue.dart`, `features/conversations/detail/chat_screen.dart`, `features/conversations/widgets/message_bubble.dart`
- [ ] Implement optimistic send & subscribe to realtime

## Templates
```dart
// channel.onPostgresChanges -> DAO.upsert()
// SendQueue.drain() -> MessagesApi.send()
```

## Completion
- Realtime chat working locally.
