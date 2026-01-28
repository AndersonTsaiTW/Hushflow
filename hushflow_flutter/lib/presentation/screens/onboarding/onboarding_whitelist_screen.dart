import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hushflow_client/inbox_butler_client.dart' as api;
import '../../../providers/api_client_provider.dart';
import '../../../providers/auth_provider.dart';

/// UI wrapper for SenderCandidate with selection state
class SenderCandidateUI {
  final api.SenderCandidate data;
  bool isSelected;

  SenderCandidateUI({
    required this.data,
    required this.isSelected,
  });

  String get email => data.email;
  String get name => data.name ?? '';
  bool get isSubscription => data.isSubscription;
  List<String> get signals => data.subscriptionSignals;
  int get emailCount => data.emailCount;

  Map<String, dynamic> toJson() => {
    'email': data.email,
    'name': data.name,
    'isSubscription': data.isSubscription,
  };
}

/// Onboarding whitelist confirmation screen
/// Shown on first login to let user select which senders are subscriptions
class OnboardingWhitelistScreen extends ConsumerStatefulWidget {
  const OnboardingWhitelistScreen({super.key});

  @override
  ConsumerState<OnboardingWhitelistScreen> createState() =>
      _OnboardingWhitelistScreenState();
}

class _OnboardingWhitelistScreenState
    extends ConsumerState<OnboardingWhitelistScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<SenderCandidateUI> _candidates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanGmail();
  }

  Future<void> _scanGmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authStateProvider).valueOrNull;
      final accessToken = authState?.accessToken;
      
      if (accessToken == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated. Please login again.';
        });
        return;
      }

      final onboarding = ref.read(onboardingEndpointProvider);
      final results = await onboarding.scanForSubscriptions(
        accessToken,
        maxEmails: 50,  // Scan 50 emails for faster performance
      );

      _candidates = results
          .map((r) => SenderCandidateUI(
                data: r,
                isSelected: r.isSubscription,
              ))
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmWhitelist() async {
    final selected = _candidates.where((c) => c.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sender')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final onboarding = ref.read(onboardingEndpointProvider);
      // TODO: Get actual userId from auth state
      const userId = 1; // Placeholder - needs real user id
      
      // Convert to typed SenderCandidate list
      final senderCandidates = selected.map((c) => api.SenderCandidate(
        email: c.email,
        name: c.name.isEmpty ? null : c.name,
        isSubscription: c.isSubscription,
        subscriptionSignals: c.signals,
        emailCount: c.emailCount,
      )).toList();
      
      final result = await onboarding.confirmWhitelist(
        userId,
        senderCandidates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.totalWhitelisted} senders added to whitelist')),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Whitelist'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => context.go('/'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Scanning your inbox...'),
            SizedBox(height: 8),
            Text(
              'Looking for newsletters and subscriptions',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanGmail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final subscriptions = _candidates.where((c) => c.isSubscription).toList();
    final others = _candidates.where((c) => !c.isSubscription).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We found ${subscriptions.length} likely subscriptions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select which senders you want Hushflow to manage. '
                  'Only emails from these senders will be stored for summaries.',
                ),
              ],
            ),
          ),
        ),
        if (subscriptions.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Detected Subscriptions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) =>
                _buildCandidateTile(subscriptions[index]),
          ),
        ],
        if (others.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Other Senders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: others.length,
            itemBuilder: (context, index) => _buildCandidateTile(others[index]),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildCandidateTile(SenderCandidateUI candidate) {
    return CheckboxListTile(
      value: candidate.isSelected,
      onChanged: (value) {
        setState(() => candidate.isSelected = value ?? false);
      },
      title: Text(
        candidate.name.isNotEmpty ? candidate.name : candidate.email,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.name.isNotEmpty)
            Text(candidate.email, style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              Text(
                '${candidate.emailCount} emails',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              if (candidate.signals.isNotEmpty) ...[
                const SizedBox(width: 8),
                ...candidate.signals.take(2).map((s) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Chip(
                        label: Text(s, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )),
              ],
            ],
          ),
        ],
      ),
      isThreeLine: true,
      secondary: CircleAvatar(
        backgroundColor: candidate.isSubscription
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          (candidate.name.isNotEmpty ? candidate.name : candidate.email)[0]
              .toUpperCase(),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading) return const SizedBox.shrink();

    final selectedCount = _candidates.where((c) => c.isSelected).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (final c in _candidates) {
                        c.isSelected = c.isSubscription;
                      }
                    });
                  },
                  child: const Text('Select detected only'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (final c in _candidates) {
                        c.isSelected = true;
                      }
                    });
                  },
                  child: const Text('Select all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _confirmWhitelist,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Confirm $selectedCount senders'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
