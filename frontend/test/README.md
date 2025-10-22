# Test Suite Documentation

This directory contains unit and integration tests for the MessageAI Flutter application.

## Test Structure

```
test/
├── services/                    # Unit tests for services
│   ├── connection_service_test.dart
│   ├── presence_service_test.dart
│   ├── typing_indicator_service_test.dart
│   └── realtime_message_service_test.dart
├── integration/                 # Integration tests
│   ├── realtime_message_flow_test.dart
│   └── presence_typing_integration_test.dart
├── offline_queue_test.dart      # Offline queue tests
└── widget_test.dart             # Widget tests

```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/services/connection_service_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Run only unit tests
```bash
flutter test test/services/
```

### Run only integration tests
```bash
flutter test test/integration/
```

## Test Categories

### Unit Tests

#### ConnectionService Tests (`services/connection_service_test.dart`)
- Initial status verification
- Status stream emission
- Exponential backoff calculation (1s, 2s, 4s, 8s, 16s, 32s, 60s max)
- Max backoff cap at 60 seconds
- Force reconnect functionality
- Stream disposal

#### PresenceService Tests (`services/presence_service_test.dart`)
- Singleton pattern verification
- Online users tracking
- User online status checks
- Stream subscription management
- Multiple conversation handling
- Resource cleanup

#### TypingIndicatorService Tests (`services/typing_indicator_service_test.dart`)
- Singleton pattern verification
- Typing users tracking
- 3-second typing timeout
- Stream subscription management
- Multiple conversation handling
- Resource cleanup

#### RealTimeMessageService Tests (`services/realtime_message_service_test.dart`)
- Singleton pattern verification
- Message stream subscriptions
- Multiple conversation handling
- Duplicate channel prevention
- Resource cleanup

### Integration Tests

#### Real-time Message Flow Tests (`integration/realtime_message_flow_test.dart`)
- Message subscription delivery
- Multiple subscription handling
- Unsubscribe behavior
- Service disposal
- Error handling
- Multiple listener support

#### Presence & Typing Integration Tests (`integration/presence_typing_integration_test.dart`)
- Independent service operation
- Separate state management
- Multiple conversation handling
- Cross-service non-interference
- Concurrent operations
- Combined disposal

## Test Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  fake_async: ^1.3.1
```

## Test Best Practices

1. **Isolation**: Each test is independent and doesn't rely on others
2. **Cleanup**: All tests properly dispose of resources in `tearDown()`
3. **Mocking**: Use mockito for external dependencies
4. **Async**: Use `fake_async` for time-based testing
5. **Coverage**: Aim for >80% code coverage

## Phase 1 Test Coverage

These tests cover the Phase 1 implementation:
- ✅ Real-time subscriptions (no polling)
- ✅ Presence tracking with Supabase Presence
- ✅ Typing indicator streams
- ✅ Connection status monitoring
- ✅ Reconnection with exponential backoff

## CI/CD Integration

Tests should be run in CI/CD pipeline:

```yaml
- name: Run tests
  run: flutter test --coverage

- name: Check coverage
  run: |
    flutter pub global activate coverage
    genhtml coverage/lcov.info -o coverage/html
```

## Troubleshooting

### Tests fail with "Supabase not initialized"
- Ensure environment variables are set in test setup
- Mock SupabaseClientProvider if needed

### Integration tests timeout
- Increase test timeout: `testWidgets('...', timeout: Timeout(Duration(minutes: 2)))`
- Check real-time connection availability

### Flaky tests
- Use `pumpAndSettle()` for async operations
- Add explicit delays where needed: `await tester.pump(Duration(milliseconds: 100))`
