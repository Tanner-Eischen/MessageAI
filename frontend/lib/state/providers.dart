import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/gen/api/clients/messages_api.dart';
import 'package:messageai/gen/api/clients/receipts_api.dart';

/// Provides the Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientProvider.client;
});

/// Provides the Supabase auth client
final authProvider = Provider<GotrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// Provides the current authenticated user
final currentUserProvider = StreamProvider<AuthUser?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges;
});

/// Provides a Dio HTTP client configured for the API
final dioProvider = Provider<Dio>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: supabase.restUrl,
      headers: {
        'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
        'apikey': supabase.auth.currentSession?.user.id ?? '',
      },
    ),
  );
  return dio;
});

/// Provides the Messages API client
final messagesApiProvider = Provider<MessagesApi>((ref) {
  final dio = ref.watch(dioProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return MessagesApi(
    dio: dio,
    baseUrl: supabase.restUrl,
  );
});

/// Provides the Receipts API client
final receiptsApiProvider = Provider<ReceiptsApi>((ref) {
  final dio = ref.watch(dioProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return ReceiptsApi(
    dio: dio,
    baseUrl: supabase.restUrl,
  );
});

/// Indicates whether the user is currently authenticated
final isAuthenticatedProvider = StreamProvider<bool>((ref) async* {
  final authState = ref.watch(currentUserProvider);
  yield* authState.when(
    data: (user) async* {
      yield user != null;
    },
    loading: () async* {
      yield false;
    },
    error: (err, st) async* {
      yield false;
    },
  );
});
