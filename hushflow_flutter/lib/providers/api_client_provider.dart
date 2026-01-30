import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:hushflow_client/inbox_butler_client.dart';

/// Serverpod API client provider
/// Provides access to all server endpoints
final apiClientProvider = Provider<Client>((ref) {
  // TODO: Make this configurable via environment
  // TODO: Replace with your actual Railway API URL
  const productionUrl = 'https://hushflow-server-production.up.railway.app/'; 
  const developmentUrl = 'http://localhost:8080/';

  // Automatically switch logic (or just hardcode it temporarily for testing)
  // const serverUrl = kReleaseMode ? productionUrl : developmentUrl;
  
  // For testing Railway from local computer:
  const serverUrl = productionUrl; // Change back to developmentUrl for local testing
  
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
