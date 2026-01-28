import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

// Mock data model (matches SenderPriority structure)
class _MockSender {
  final String email;
  final String name;
  final double maxScore;
  final String latestSnippet;
  final DateTime latestReceivedAt;
  final int emailCount;
  final bool isWhitelisted;

  _MockSender({
    required this.email,
    required this.name,
    required this.maxScore,
    required this.latestSnippet,
    required this.latestReceivedAt,
    required this.emailCount,
    this.isWhitelisted = false,
  });
}

class CleanupScreen extends ConsumerStatefulWidget {
  const CleanupScreen({super.key});

  @override
  ConsumerState<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends ConsumerState<CleanupScreen> {
  final Set<String> _selectedEmails = {};
  bool _selectAll = false;
  String _filterMode = 'stale'; // stale, spam, promotional

  // Realistic mock data
  final List<_MockSender> _mockSenders = [
    _MockSender(
      email: 'newsletter@medium.com',
      name: 'Medium Daily Digest',
      maxScore: 0.15,
      latestSnippet: 'Top stories for you today: The Future of AI, How to Build...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 47)),
      emailCount: 124,
    ),
    _MockSender(
      email: 'deals@groupon.com',
      name: 'Groupon Deals',
      maxScore: 0.08,
      latestSnippet: '50% off dining! Limited time offer on local restaurants...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 63)),
      emailCount: 89,
    ),
    _MockSender(
      email: 'notifications@linkedin.com',
      name: 'LinkedIn',
      maxScore: 0.22,
      latestSnippet: 'You appeared in 12 searches this week. See who viewed your...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 35)),
      emailCount: 156,
    ),
    _MockSender(
      email: 'promo@amazon.com',
      name: 'Amazon Promotions',
      maxScore: 0.18,
      latestSnippet: 'Exclusive deals just for you! Save up to 70% on electronics...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 41)),
      emailCount: 203,
    ),
    _MockSender(
      email: 'updates@pinterest.com',
      name: 'Pinterest Weekly',
      maxScore: 0.12,
      latestSnippet: 'New ideas for you based on Home Decor, Recipes, and more...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 55)),
      emailCount: 78,
    ),
    _MockSender(
      email: 'hello@duolingo.com',
      name: 'Duolingo',
      maxScore: 0.31,
      latestSnippet: "You're on a 5-day streak! Don't lose it now. Practice Spanish...",
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 92)),
      emailCount: 45,
    ),
    _MockSender(
      email: 'marketing@shopify.com',
      name: 'Shopify News',
      maxScore: 0.09,
      latestSnippet: 'Grow your business with these proven marketing strategies...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 71)),
      emailCount: 67,
    ),
    _MockSender(
      email: 'noreply@github.com',
      name: 'GitHub Notifications',
      maxScore: 0.42,
      latestSnippet: '[repo-name] New issue opened: Bug in authentication module...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 28)),
      emailCount: 312,
    ),
    _MockSender(
      email: 'updates@spotify.com',
      name: 'Spotify',
      maxScore: 0.19,
      latestSnippet: 'Your Discover Weekly is ready! New music picked just for you...',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 44)),
      emailCount: 52,
    ),
    _MockSender(
      email: 'offers@uber.com',
      name: 'Uber',
      maxScore: 0.14,
      latestSnippet: 'Get 20% off your next 3 rides. Offer expires soon!',
      latestReceivedAt: DateTime.now().subtract(const Duration(days: 38)),
      emailCount: 91,
    ),
  ];

  int get _totalStaleCount => _mockSenders.length;
  int get _totalEmailsCount => _mockSenders.fold(0, (sum, s) => sum + s.emailCount);

  @override
  Widget build(BuildContext context) {
    final filteredSenders = _mockSenders.where((s) {
      if (_filterMode == 'stale') return true;
      if (_filterMode == 'spam') return s.maxScore < 0.2;
      if (_filterMode == 'promotional') return s.emailCount > 100;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleanup Butler'),
        elevation: 0,
        actions: [
          if (_selectedEmails.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedEmails.length} selected',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() {
                      _selectedEmails.clear();
                      _selectAll = false;
                    }),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header - Compact Version
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.errorContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cleaning_services,
                    size: 24,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_totalStaleCount Stale Senders',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalEmailsCount emails taking up space',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Stale (30+ days)',
                    icon: Icons.hourglass_empty,
                    isSelected: _filterMode == 'stale',
                    onTap: () => setState(() => _filterMode = 'stale'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low Priority',
                    icon: Icons.arrow_downward,
                    isSelected: _filterMode == 'spam',
                    onTap: () => setState(() => _filterMode = 'spam'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High Volume',
                    icon: Icons.mail_outline,
                    isSelected: _filterMode == 'promotional',
                    onTap: () => setState(() => _filterMode = 'promotional'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Select All Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (v) => setState(() {
                    _selectAll = v ?? false;
                    if (_selectAll) {
                      _selectedEmails.addAll(filteredSenders.map((s) => s.email));
                    } else {
                      _selectedEmails.clear();
                    }
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  'Select all',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedEmails.length} of ${filteredSenders.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Sender List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: filteredSenders.length,
              itemBuilder: (context, index) {
                final sender = filteredSenders[index];
                final isSelected = _selectedEmails.contains(sender.email);
                final daysAgo = DateTime.now().difference(sender.latestReceivedAt).inDays;

                return _SenderCard(
                  sender: sender,
                  isSelected: isSelected,
                  daysAgo: daysAgo,
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedEmails.remove(sender.email);
                    } else {
                      _selectedEmails.add(sender.email);
                    }
                    _selectAll = _selectedEmails.length == filteredSenders.length;
                  }),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedEmails.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleAction('trash'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _handleAction('unsubscribe'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          icon: const Icon(Icons.unsubscribe),
                          label: const Text('Unsubscribe'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _handleAction(String action) {
    final count = _selectedEmails.length;
    final emailCount = _mockSenders
        .where((s) => _selectedEmails.contains(s.email))
        .fold(0, (sum, s) => sum + s.emailCount);

    setState(() {
      _selectedEmails.clear();
      _selectAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'unsubscribe'
              ? 'Unsubscribed from $count senders ($emailCount emails)'
              : 'Deleted $count senders ($emailCount emails)',
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sender Card Widget
class _SenderCard extends StatelessWidget {
  final _MockSender sender;
  final bool isSelected;
  final int daysAgo;
  final VoidCallback onTap;

  const _SenderCard({
    required this.sender,
    required this.isSelected,
    required this.daysAgo,
    required this.onTap,
  });

  Color _getPriorityColor(BuildContext context) {
    if (sender.maxScore >= 0.4) return Colors.green.shade700;
    if (sender.maxScore >= 0.2) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isSelected ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Name & Priority Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 12,
                                color: _getPriorityColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(sender.maxScore * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getPriorityColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Email Address
                    Text(
                      sender.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Latest Snippet
                    Text(
                      sender.latestSnippet,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Stats Row
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sender.emailCount} emails',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$daysAgo days ago',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
