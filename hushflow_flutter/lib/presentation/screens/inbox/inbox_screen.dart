import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hushflow_client/hushflow_client.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../providers/api_client_provider.dart';
import '../../../providers/auth_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _showSubscriptionsOnly = false;
  bool _isLoading = true;
  List<SenderPriority> _senders = [];
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadInbox();
  }
  
  Future<void> _loadInbox() async {
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
          _error = 'Not authenticated';
        });
        return;
      }

      final mlEndpoint = ref.read(mlEndpointProvider);
      // TODO: Get real userId
      const userId = 1;
      
      final results = await mlEndpoint.analyzeInbox(
        accessToken,
        userId,
        maxEmails: 50,  // Scan 50 emails for faster performance
      );
      
      if (mounted) {
        setState(() {
          _senders = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load inbox: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter senders based on toggle
    final filteredSenders = _senders.where((s) {
      if (_showSubscriptionsOnly && !s.latestSnippet.toLowerCase().contains('unsubscribe')) {
          // Simple check as isWhitelisted/isSubscription might not be fully populated yet
          return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: Icon(_showSubscriptionsOnly ? Icons.mark_email_read : Icons.mail),
            onPressed: () => setState(() => _showSubscriptionsOnly = !_showSubscriptionsOnly),
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _loadInbox,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadInbox, child: const Text('Retry')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).signOut();
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ))
          : RefreshIndicator(
        onRefresh: _loadInbox,
        child: CustomScrollView(
          slivers: [
            if (filteredSenders.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No emails found')),
              )
            else
              SliverList.builder(
                itemCount: filteredSenders.length,
                itemBuilder: (context, index) {
                  final sender = filteredSenders[index];
                  final score = sender.maxScore;
                  final isHighPriority = score >= 0.7;
                  
                  return _EmailTile(
                    sender: sender.name,
                    subject: sender.email, // Show email as "subject" context for now or snippet
                    snippet: sender.latestSnippet,
                    receivedAt: sender.latestReceivedAt,
                    isRead: true, // Not tracking read state per sender yet
                    isSubscription: false,
                    priorityScore: score,
                    onTap: () {}, // TODO: Detail view
                    onExclude: () {},
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmailTile extends StatelessWidget {
  final String sender, subject, snippet;
  final DateTime receivedAt;
  final bool isRead, isSubscription;
  final double priorityScore;
  final VoidCallback onTap, onExclude;

  const _EmailTile({
    required this.sender, required this.subject, required this.snippet,
    required this.receivedAt, required this.isRead, required this.isSubscription,
    required this.priorityScore, required this.onTap, required this.onExclude,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: priorityScore >= 0.7 ? Colors.green.withOpacity(0.2) : null,
        child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?'),
      ),
      title: Row(
        children: [
          Expanded(child: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(timeago.format(receivedAt), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(snippet, maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Icon(Icons.auto_graph, size: 12, color: priorityScore > 0.7 ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Text('${(priorityScore * 100).toInt()}%', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              if (priorityScore > 0.7)
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text('High Priority', style: TextStyle(fontSize: 10, color: Colors.green)),
                 )
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
