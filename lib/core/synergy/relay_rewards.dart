import '../blockchain/blockchain.dart';
import 'package:logger/logger.dart';

/// Rewards for hosting NOSTR relays
/// Synergy: NOSTR Relay + Compute = Earn tokens for providing infrastructure
class RelayRewardsSystem {
  final Blockchain blockchain;
  final Logger _logger = Logger();

  // Reward rates per relay metric
  static const double rewardPerConnection = 0.01;
  static const double rewardPerEvent = 0.001;
  static const double rewardPerGBTransferred = 1.0;

  RelayRewardsSystem({required this.blockchain});

  /// Record relay hosting contribution
  Future<RelayReward> recordRelayHosting({
    required String userId,
    required String relayUrl,
    required int activeConnections,
    required int eventsRelayed,
    required double bandwidthGB,
    required Duration uptime,
  }) async {
    // Calculate rewards
    final connectionReward = activeConnections * rewardPerConnection;
    final eventReward = eventsRelayed * rewardPerEvent;
    final bandwidthReward = bandwidthGB * rewardPerGBTransferred;
    final uptimeBonus = _calculateUptimeBonus(uptime);

    final totalReward = connectionReward + eventReward + bandwidthReward + uptimeBonus;

    // Record on blockchain
    blockchain.addBlock({
      'type': 'relay_hosting',
      'userId': userId,
      'relayUrl': relayUrl,
      'activeConnections': activeConnections,
      'eventsRelayed': eventsRelayed,
      'bandwidthGB': bandwidthGB,
      'uptime': uptime.inHours,
      'connectionReward': connectionReward,
      'eventReward': eventReward,
      'bandwidthReward': bandwidthReward,
      'uptimeBonus': uptimeBonus,
      'totalReward': totalReward,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Relay hosting reward: $totalReward tokens for $relayUrl');

    return RelayReward(
      userId: userId,
      relayUrl: relayUrl,
      activeConnections: activeConnections,
      eventsRelayed: eventsRelayed,
      bandwidthGB: bandwidthGB,
      uptime: uptime,
      connectionReward: connectionReward,
      eventReward: eventReward,
      bandwidthReward: bandwidthReward,
      uptimeBonus: uptimeBonus,
      totalReward: totalReward,
    );
  }

  /// Calculate uptime bonus (up to 24 hours)
  double _calculateUptimeBonus(Duration uptime) {
    final hours = uptime.inHours.clamp(0, 24);
    return hours * 0.5; // 0.5 tokens per hour of uptime
  }

  /// Get total relay rewards for user
  Future<double> getTotalRelayRewards(String userId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'relay_hosting' && data['userId'] == userId);

    return blocks.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['totalReward'] as num).toDouble(),
    );
  }

  /// Get relay statistics
  Future<RelayStats> getRelayStats(String userId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'relay_hosting' && data['userId'] == userId);

    final totalEvents = blocks.fold<int>(
      0,
      (sum, block) => sum + (block.data['eventsRelayed'] as int),
    );

    final totalBandwidth = blocks.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['bandwidthGB'] as num).toDouble(),
    );

    final totalUptime = blocks.fold<int>(
      0,
      (sum, block) => sum + (block.data['uptime'] as int),
    );

    final totalRewards = await getTotalRelayRewards(userId);

    return RelayStats(
      userId: userId,
      totalRelays: blocks.length,
      totalEvents: totalEvents,
      totalBandwidthGB: totalBandwidth,
      totalUptimeHours: totalUptime,
      totalRewards: totalRewards,
    );
  }

  /// Get network-wide relay statistics
  Future<Map<String, dynamic>> getNetworkStats() async {
    final blocks = blockchain.getBlocksByType('relay_hosting');

    final totalRelays = blocks
        .map((b) => b.data['relayUrl'])
        .toSet()
        .length;

    final totalEvents = blocks.fold<int>(
      0,
      (sum, block) => sum + (block.data['eventsRelayed'] as int? ?? 0),
    );

    final totalRewards = blocks.fold<double>(
      0.0,
      (sum, block) => sum + ((block.data['totalReward'] as num?)?.toDouble() ?? 0.0),
    );

    return {
      'totalRelays': totalRelays,
      'totalEvents': totalEvents,
      'totalRewardsDistributed': totalRewards,
      'averageRewardPerRelay': totalRelays > 0 ? totalRewards / totalRelays : 0.0,
    };
  }
}

/// Relay hosting reward
class RelayReward {
  final String userId;
  final String relayUrl;
  final int activeConnections;
  final int eventsRelayed;
  final double bandwidthGB;
  final Duration uptime;
  final double connectionReward;
  final double eventReward;
  final double bandwidthReward;
  final double uptimeBonus;
  final double totalReward;

  RelayReward({
    required this.userId,
    required this.relayUrl,
    required this.activeConnections,
    required this.eventsRelayed,
    required this.bandwidthGB,
    required this.uptime,
    required this.connectionReward,
    required this.eventReward,
    required this.bandwidthReward,
    required this.uptimeBonus,
    required this.totalReward,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'relayUrl': relayUrl,
    'activeConnections': activeConnections,
    'eventsRelayed': eventsRelayed,
    'bandwidthGB': bandwidthGB,
    'uptimeHours': uptime.inHours,
    'connectionReward': connectionReward,
    'eventReward': eventReward,
    'bandwidthReward': bandwidthReward,
    'uptimeBonus': uptimeBonus,
    'totalReward': totalReward,
  };
}

/// Relay hosting statistics
class RelayStats {
  final String userId;
  final int totalRelays;
  final int totalEvents;
  final double totalBandwidthGB;
  final int totalUptimeHours;
  final double totalRewards;

  RelayStats({
    required this.userId,
    required this.totalRelays,
    required this.totalEvents,
    required this.totalBandwidthGB,
    required this.totalUptimeHours,
    required this.totalRewards,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalRelays': totalRelays,
    'totalEvents': totalEvents,
    'totalBandwidthGB': totalBandwidthGB,
    'totalUptimeHours': totalUptimeHours,
    'totalRewards': totalRewards,
  };
}
