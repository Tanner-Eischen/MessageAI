// Basic Flutter widget test for MessageAI app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/app.dart';

void main() {
  testWidgets('MessageAI app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MessageAIApp(),
      ),
    );

    // Verify app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
