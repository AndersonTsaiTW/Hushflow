import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hushflow_client/inbox_butler_client.dart';

/// Serverpod API client provider
/// Provides access to all server endpoints
final apiClientProvider = Provider<Client>((ref) {
  // TODO: Make this configurable via environment
  const serverUrl = 'http://localhost:8080/';
  
  return Client(
    serverUrl,
    connectionTimeout: const Duration(seconds: 180), // 3 minutes for scanning 200 emails
  );
});

/// Convenience providers for specific endpoints
final onboardingEndpointProvider = Provider<EndpointOnboarding>((ref) {
  return ref.watch(apiClientProvider).onboarding;
});

final emailEndpointProvider = Provider<EndpointEmail>((ref) {
  return ref.watch(apiClientProvider).email;
});

final summaryEndpointProvider = Provider<EndpointSummary>((ref) {
  return ref.watch(apiClientProvider).summary;
});

final cleanupEndpointProvider = Provider<EndpointCleanup>((ref) {
  return ref.watch(apiClientProvider).cleanup;
});

final mlEndpointProvider = Provider<EndpointMl>((ref) {
  return ref.watch(apiClientProvider).ml;
});
