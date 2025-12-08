import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/tokens/app_token.dart';
import '../../core/nostr/nostr_event.dart';
import '../../core/nostr/nostr_relay.dart';
import '../hub/providers/hub_providers.dart';

/// NOSTR social feed view
class NostrFeedView extends ConsumerStatefulWidget {
  final AppToken token;

  const NostrFeedView({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<NostrFeedView> createState() => _NostrFeedViewState();
}

class _NostrFeedViewState extends ConsumerState<NostrFeedView> {
  final List<NostrEvent> _events = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeNostr();
  }

  Future<void> _initializeNostr() async {
    final client = ref.read(nostrClientProvider);

    // Add default relays
    for (final relay in NostrRelay.getDefaults()) {
      client.addRelay(relay);
    }

    // Connect to relays
    await client.connectAll();

    // Subscribe to text notes
    client.subscribe({
      'kinds': [NostrEventKind.textNote],
      'limit': 50,
    });

    // Listen to events
    client.events.listen((event) {
      if (mounted) {
        setState(() {
          _events.insert(0, event);
          if (_events.length > 100) {
            _events.removeLast();
          }
        });
      }
    });

    setState(() {
      _isConnected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return _buildLoadingState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _initializeNostr();
      },
      child: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _NostrEventCard(event: event);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to NOSTR relays...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for NOSTR events...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _NostrEventCard extends StatelessWidget {
  final NostrEvent event;

  const _NostrEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    event.pubkey.substring(0, 2).toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.pubkey.substring(0, 16)}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTimestamp(event.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildKindBadge(event.kind),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.content,
              style: const TextStyle(fontSize: 15),
            ),
            if (event.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: event.tags
                    .where((tag) => tag.isNotEmpty && tag[0] == 't')
                    .map((tag) => Chip(
                          label: Text(
                            '#${tag.length > 1 ? tag[1] : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKindBadge(int kind) {
    String label;
    Color color;

    switch (kind) {
      case NostrEventKind.textNote:
        label = 'Note';
        color = Colors.blue;
        break;
      case NostrEventKind.metadata:
        label = 'Profile';
        color = Colors.green;
        break;
      case NostrEventKind.reaction:
        label = 'Reaction';
        color = Colors.orange;
        break;
      default:
        label = 'Kind $kind';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
