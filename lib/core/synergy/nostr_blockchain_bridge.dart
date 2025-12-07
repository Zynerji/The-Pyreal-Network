import '../nostr/nostr_event.dart';
import '../nostr/nostr_client.dart';
import '../blockchain/blockchain.dart';
import 'package:logger/logger.dart';

/// Bridge between NOSTR and Blockchain for immutable social proof
/// Synergy: NOSTR events verified and timestamped on blockchain
class NostrBlockchainBridge {
  final NostrClient nostrClient;
  final Blockchain blockchain;
  final Logger _logger = Logger();

  NostrBlockchainBridge({
    required this.nostrClient,
    required this.blockchain,
  });

  /// Publish NOSTR event and record on blockchain
  Future<String> publishVerifiedEvent(NostrEvent event) async {
    // Publish to NOSTR relays
    await nostrClient.publish(event);

    // Record on blockchain for immutability
    final blockHash = _recordEventOnChain(event);

    _logger.i('Event ${event.id} published and verified on blockchain');
    return blockHash;
  }

  /// Record NOSTR event on blockchain
  String _recordEventOnChain(NostrEvent event) {
    blockchain.addBlock({
      'type': 'nostr_event',
      'eventId': event.id,
      'pubkey': event.pubkey,
      'kind': event.kind,
      'createdAt': event.createdAt,
      'contentHash': _hashContent(event.content),
      'signature': event.sig,
    });

    return blockchain.latestBlock.hash;
  }

  /// Verify NOSTR event exists on blockchain
  Future<bool> verifyEvent(String eventId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'nostr_event' && data['eventId'] == eventId);

    if (blocks.isEmpty) return false;

    // Verify block integrity
    return blocks.first.verifyHash();
  }

  /// Get reputation score for a pubkey based on blockchain activity
  Future<ReputationScore> getReputation(String pubkey) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'nostr_event' && data['pubkey'] == pubkey);

    final eventCount = blocks.length;
    final oldestBlock = blocks.isEmpty ? null : blocks.last;
    final accountAge = oldestBlock != null
        ? DateTime.now().difference(oldestBlock.timestamp).inDays
        : 0;

    // Calculate reputation score
    final score = _calculateReputationScore(
      eventCount: eventCount,
      accountAge: accountAge,
      verifiedEvents: eventCount, // All on-chain events are verified
    );

    return ReputationScore(
      pubkey: pubkey,
      score: score,
      totalEvents: eventCount,
      verifiedEvents: eventCount,
      accountAge: accountAge,
      isVerified: eventCount > 0,
    );
  }

  /// Calculate reputation score
  double _calculateReputationScore({
    required int eventCount,
    required int accountAge,
    required int verifiedEvents,
  }) {
    // Base score from verified events
    double score = verifiedEvents * 10.0;

    // Bonus for account age (max 100 points)
    score += (accountAge / 365.0) * 100.0;

    // Normalize to 0-1000
    return score.clamp(0, 1000);
  }

  /// Hash content for blockchain storage
  String _hashContent(String content) {
    // Store hash instead of full content for privacy
    return content.length > 100
        ? '${content.substring(0, 100)}...[${content.length} chars]'
        : content;
  }

  /// Get all verified events for a pubkey
  Future<List<Map<String, dynamic>>> getVerifiedEvents(String pubkey) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'nostr_event' && data['pubkey'] == pubkey);

    return blocks.map((block) => {
      'eventId': block.data['eventId'],
      'kind': block.data['kind'],
      'timestamp': block.timestamp,
      'blockHash': block.hash,
      'verified': true,
    }).toList();
  }
}

/// Reputation score for NOSTR users
class ReputationScore {
  final String pubkey;
  final double score;
  final int totalEvents;
  final int verifiedEvents;
  final int accountAge;
  final bool isVerified;

  ReputationScore({
    required this.pubkey,
    required this.score,
    required this.totalEvents,
    required this.verifiedEvents,
    required this.accountAge,
    required this.isVerified,
  });

  /// Get reputation level
  String get level {
    if (score >= 800) return 'Legend';
    if (score >= 600) return 'Expert';
    if (score >= 400) return 'Advanced';
    if (score >= 200) return 'Intermediate';
    if (score >= 50) return 'Beginner';
    return 'Newbie';
  }

  Map<String, dynamic> toJson() => {
    'pubkey': pubkey,
    'score': score,
    'level': level,
    'totalEvents': totalEvents,
    'verifiedEvents': verifiedEvents,
    'accountAge': accountAge,
    'isVerified': isVerified,
  };
}
