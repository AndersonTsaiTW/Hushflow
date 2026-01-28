import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hushflow_client/hushflow_client.dart';
import '../../../providers/api_client_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class SummaryDetailScreen extends ConsumerStatefulWidget {
  final int summaryId;
  const SummaryDetailScreen({super.key, required this.summaryId});

  @override
  ConsumerState<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends ConsumerState<SummaryDetailScreen> {
  bool _isLoading = true;
  SummaryDetails? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authState = ref.read(authStateProvider).valueOrNull;
      final accessToken = authState?.accessToken;
      
      if (accessToken == null) throw Exception('Not authenticated');

      final details = await ref.read(summaryEndpointProvider).getSummaryDetails(
        accessToken, 
        widget.summaryId
      );
      
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $_error')));
    if (_details == null) return const Scaffold(body: Center(child: Text('Not found')));

    final summary = _details!.summary;
    final items = _details!.items;
    final dateFormat = DateFormat('MMM d');
    
    // Sort items by priority score (highest first)
    final sortedItems = List<SummaryItem>.from(items)
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Digest'),
        actions: [
          IconButton(icon: const Icon(Icons.headphones), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(summary.periodStart)} - ${dateFormat.format(summary.periodEnd)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.email, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.emailCount} emails',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summary.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          
          // Grid Section Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.grid_view, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Key Highlights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Staggered Grid of Email Items
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                return _buildItemCard(context, item, index);
              },
            ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, SummaryItem item, int index) {
    final priority = item.priorityScore;
    
    // Determine card type based on priority
    if (priority >= 0.8 && index == 0) {
      // Hero card - full width for the highest priority item
      return _HeroCard(item: item);
    } else if (priority >= 0.5) {
      // Medium priority card
      return _MediumCard(item: item);
    } else {
      // Low priority compact card
      return _CompactCard(item: item);
    }
  }
}

// Hero Card - Large, featured card for highest priority items
class _HeroCard extends StatelessWidget {
  final SummaryItem item;
  
  const _HeroCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priorityPercent = (item.priorityScore * 100).toInt();
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to full email detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open email: ${item.subject}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image_not_supported, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _PriorityBadge(score: priorityPercent, isHero: true),
                  ),
                ],
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.priority_high, size: 48, color: Colors.white.withOpacity(0.5)),
                ),
              ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          item.sender.isNotEmpty ? item.sender[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.sender,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Subject (larger for hero card)
                  Text(
                    item.subject,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Summary
                  Text(
                    item.summaryText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Medium Card - Standard card for medium priority items
class _MediumCard extends StatelessWidget {
  final SummaryItem item;
  
  const _MediumCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priorityPercent = (item.priorityScore * 100).toInt();
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open email: ${item.subject}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smaller image for medium cards
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: Icon(Icons.image_not_supported, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _PriorityBadge(score: priorityPercent),
                  ),
                ],
              ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: Text(
                          item.sender.isNotEmpty ? item.sender[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.sender,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.imageUrl == null || item.imageUrl!.isEmpty)
                        _PriorityBadge(score: priorityPercent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Subject
                  Text(
                    item.subject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Summary
                  Text(
                    item.summaryText,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Card - Minimal card for lower priority items
class _CompactCard extends StatelessWidget {
  final SummaryItem item;
  
  const _CompactCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priorityPercent = (item.priorityScore * 100).toInt();
    
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open email: ${item.subject}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender and priority
              Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Text(
                      item.sender.isNotEmpty ? item.sender[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onTertiaryContainer),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.sender,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _PriorityBadge(score: priorityPercent, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              
              // Subject
              Text(
                item.subject,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Summary (minimal)
              Text(
                item.summaryText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Priority Badge Component
class _PriorityBadge extends StatelessWidget {
  final int score;
  final bool isHero;
  final bool compact;
  
  const _PriorityBadge({
    required this.score,
    this.isHero = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;
    
    if (score >= 80) {
      badgeColor = Colors.red.shade700;
      icon = Icons.priority_high;
    } else if (score >= 60) {
      badgeColor = Colors.orange.shade700;
      icon = Icons.star;
    } else if (score >= 40) {
      badgeColor = Colors.blue.shade700;
      icon = Icons.bookmark;
    } else {
      badgeColor = Colors.grey.shade600;
      icon = Icons.circle;
    }
    
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isHero ? 12 : 8,
        vertical: isHero ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isHero ? 16 : 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: Colors.white,
              fontSize: isHero ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
