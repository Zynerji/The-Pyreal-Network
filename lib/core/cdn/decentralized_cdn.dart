import 'dart:async';
import 'dart:math';
import '../blockchain/blockchain.dart';
import '../orchestration/conductor.dart';
import '../storage/hdp_storage.dart';
import 'package:logger/logger.dart';

/// Content types supported by CDN
enum ContentType {
  video,
  audio,
  image,
  document,
  software,
  dataset,
  livestream,
}

/// CDN node geographic regions
enum CDNRegion {
  northAmericaEast,
  northAmericaWest,
  europeWest,
  europeEast,
  asiaPacific,
  southAmerica,
  africa,
  oceania,
}

/// Content delivery statistics
class DeliveryStats {
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final double totalBandwidthGB;
  final double averageLatencyMs;
  final Map<CDNRegion, int> requestsByRegion;

  const DeliveryStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.totalBandwidthGB,
    required this.averageLatencyMs,
    required this.requestsByRegion,
  });

  double get cacheHitRate => totalRequests > 0 ? cacheHits / totalRequests : 0.0;

  Map<String, dynamic> toJson() => {
        'totalRequests': totalRequests,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'cacheHitRate': cacheHitRate,
        'totalBandwidthGB': totalBandwidthGB,
        'averageLatencyMs': averageLatencyMs,
        'requestsByRegion': requestsByRegion.map((k, v) => MapEntry(k.name, v)),
      };
}

/// CDN node information
class CDNNode {
  final String nodeId;
  final CDNRegion region;
  final double storageCapacityGB;
  final double bandwidthMbps;
  final double uptimePercentage;
  final int fragmentsHosted;
  final double totalEarnedPyreal;

  const CDNNode({
    required this.nodeId,
    required this.region,
    required this.storageCapacityGB,
    required this.bandwidthMbps,
    required this.uptimePercentage,
    this.fragmentsHosted = 0,
    this.totalEarnedPyreal = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'region': region.name,
        'storageCapacityGB': storageCapacityGB,
        'bandwidthMbps': bandwidthMbps,
        'uptimePercentage': uptimePercentage,
        'fragmentsHosted': fragmentsHosted,
        'totalEarnedPyreal': totalEarnedPyreal,
      };
}

/// Content uploaded to CDN
class CDNContent {
  final String contentId;
  final String ownerId;
  final String name;
  final ContentType type;
  final double sizeGB;
  final String hdpHash;
  final List<String> fragmentHashes;
  final int totalDownloads;
  final double totalBandwidthGB;
  final double totalCostPyreal;
  final DateTime uploadedAt;
  final Map<CDNRegion, List<String>> fragmentDistribution;

  const CDNContent({
    required this.contentId,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.sizeGB,
    required this.hdpHash,
    required this.fragmentHashes,
    this.totalDownloads = 0,
    this.totalBandwidthGB = 0.0,
    this.totalCostPyreal = 0.0,
    required this.uploadedAt,
    required this.fragmentDistribution,
  });

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'ownerId': ownerId,
        'name': name,
        'type': type.name,
        'sizeGB': sizeGB,
        'hdpHash': hdpHash,
        'fragmentHashes': fragmentHashes,
        'totalDownloads': totalDownloads,
        'totalBandwidthGB': totalBandwidthGB,
        'totalCostPyreal': totalCostPyreal,
        'uploadedAt': uploadedAt.toIso8601String(),
        'fragmentDistribution': fragmentDistribution.map(
          (k, v) => MapEntry(k.name, v),
        ),
      };
}

/// Decentralized Content Delivery Network
class DecentralizedCDN {
  final Blockchain blockchain;
  final Conductor conductor;
  final HDPStorage hdpStorage;
  final Logger _logger = Logger();

  final Map<String, CDNNode> _nodes = {};
  final Map<String, CDNContent> _content = {};
  final Map<String, List<String>> _nodeFragments = {}; // nodeId -> fragmentIds

  // Pricing constants (in PYREAL per GB)
  static const double _pricePerGBStreamed = 0.1; // 0.1 ₱ per GB
  static const double _storageRewardPerGBMonth = 0.05; // 0.05 ₱ per GB per month

  DecentralizedCDN({
    required this.blockchain,
    required this.conductor,
    required this.hdpStorage,
  });

  /// Register a node as CDN provider
  Future<CDNNode> registerNode({
    required String nodeId,
    required CDNRegion region,
    required double storageCapacityGB,
    required double bandwidthMbps,
  }) async {
    _logger.i('Registering CDN node: $nodeId in ${region.name}');

    final node = CDNNode(
      nodeId: nodeId,
      region: region,
      storageCapacityGB: storageCapacityGB,
      bandwidthMbps: bandwidthMbps,
      uptimePercentage: 99.0,
    );

    _nodes[nodeId] = node;
    _nodeFragments[nodeId] = [];

    _logger.i('CDN node registered: $nodeId with ${storageCapacityGB}GB capacity');

    return node;
  }

  /// Upload content to decentralized CDN
  Future<CDNContent> uploadContent({
    required String ownerId,
    required String name,
    required ContentType type,
    required List<int> data,
    List<CDNRegion>? priorityRegions,
  }) async {
    final contentId = _generateContentId();
    final sizeGB = data.length / (1024 * 1024 * 1024);

    _logger.i('Uploading content: $name ($sizeGB GB)');

    // Step 1: Fragment content using HDP (70% reconstruction threshold)
    final hdpHash = await hdpStorage.storeData(
      data: data,
      userId: ownerId,
    );

    // Get fragment hashes from HDP
    final fragmentHashes = await hdpStorage.getFragments(hdpHash);

    _logger.i('Content fragmented into ${fragmentHashes.length} fragments');

    // Step 2: Distribute fragments geographically
    final fragmentDistribution = await _distributeFragments(
      fragmentHashes: fragmentHashes,
      sizeGB: sizeGB,
      priorityRegions: priorityRegions,
    );

    final content = CDNContent(
      contentId: contentId,
      ownerId: ownerId,
      name: name,
      type: type,
      sizeGB: sizeGB,
      hdpHash: hdpHash,
      fragmentHashes: fragmentHashes,
      uploadedAt: DateTime.now(),
      fragmentDistribution: fragmentDistribution,
    );

    _content[contentId] = content;

    _logger.i('Content uploaded successfully: $contentId');

    return content;
  }

  /// Distribute fragments across CDN nodes
  Future<Map<CDNRegion, List<String>>> _distributeFragments({
    required List<String> fragmentHashes,
    required double sizeGB,
    List<CDNRegion>? priorityRegions,
  }) async {
    final distribution = <CDNRegion, List<String>>{};

    // Calculate fragments per region based on node availability
    final regionNodes = _groupNodesByRegion();

    for (final region in CDNRegion.values) {
      if (!regionNodes.containsKey(region) || regionNodes[region]!.isEmpty) {
        continue;
      }

      // Allocate 3-5 fragments per region for redundancy
      final fragmentsForRegion = min(5, fragmentHashes.length);
      final selectedFragments = fragmentHashes.take(fragmentsForRegion).toList();

      distribution[region] = selectedFragments;

      // Assign fragments to specific nodes in this region
      final nodesInRegion = regionNodes[region]!;
      for (var i = 0; i < selectedFragments.length; i++) {
        final nodeIndex = i % nodesInRegion.length;
        final node = nodesInRegion[nodeIndex];
        _nodeFragments[node.nodeId]!.add(selectedFragments[i]);
      }
    }

    _logger.i('Fragments distributed across ${distribution.length} regions');

    return distribution;
  }

  /// Request content delivery (streaming or download)
  Future<Map<String, dynamic>> requestContent({
    required String contentId,
    required String userId,
    required CDNRegion userRegion,
  }) async {
    final content = _content[contentId];
    if (content == null) {
      throw Exception('Content not found: $contentId');
    }

    _logger.i('Content requested: ${content.name} from ${userRegion.name}');

    // Find optimal nodes to serve this request
    final optimalNodes = await _findOptimalNodes(
      fragmentHashes: content.fragmentHashes,
      userRegion: userRegion,
      requiredFragments: (content.fragmentHashes.length * 0.7).ceil(), // 70% threshold
    );

    if (optimalNodes.isEmpty) {
      throw Exception('No available nodes to serve content');
    }

    // Calculate delivery cost
    final deliveryCost = content.sizeGB * _pricePerGBStreamed;

    // Check user balance
    final balance = await blockchain.getBalance(userId);
    if (balance < deliveryCost) {
      throw Exception('Insufficient balance: $balance ₱ < $deliveryCost ₱');
    }

    // Process payment to serving nodes
    await _processContentDeliveryPayment(
      content: content,
      userId: userId,
      servingNodes: optimalNodes,
      totalCost: deliveryCost,
    );

    // Update statistics
    await _updateDeliveryStats(content, userRegion);

    _logger.i('Content delivered: ${content.name} for $deliveryCost ₱');

    return {
      'contentId': contentId,
      'servingNodes': optimalNodes.map((n) => n.nodeId).toList(),
      'deliveryCost': deliveryCost,
      'estimatedLatencyMs': _calculateEstimatedLatency(optimalNodes, userRegion),
      'fragmentsRequired': (content.fragmentHashes.length * 0.7).ceil(),
    };
  }

  /// Find optimal nodes to serve content request
  Future<List<CDNNode>> _findOptimalNodes({
    required List<String> fragmentHashes,
    required CDNRegion userRegion,
    required int requiredFragments,
  }) async {
    final candidates = <CDNNode>[];

    // Prioritize nodes in same region, then nearby regions
    final regionPriority = _getRegionPriority(userRegion);

    for (final region in regionPriority) {
      final nodesInRegion = _nodes.values.where((n) => n.region == region).toList();

      for (final node in nodesInRegion) {
        final nodeFragments = _nodeFragments[node.nodeId] ?? [];
        final hasRelevantFragments = nodeFragments.any((f) => fragmentHashes.contains(f));

        if (hasRelevantFragments && node.uptimePercentage > 95.0) {
          candidates.add(node);
        }
      }

      // If we have enough nodes, stop searching
      if (candidates.length >= requiredFragments) {
        break;
      }
    }

    // Sort by uptime and bandwidth
    candidates.sort((a, b) {
      final scoreA = a.uptimePercentage * a.bandwidthMbps;
      final scoreB = b.uptimePercentage * b.bandwidthMbps;
      return scoreB.compareTo(scoreA);
    });

    return candidates.take(requiredFragments).toList();
  }

  /// Process payment for content delivery
  Future<void> _processContentDeliveryPayment({
    required CDNContent content,
    required String userId,
    required List<CDNNode> servingNodes,
    required double totalCost,
  }) async {
    // Revenue split: 85% to serving nodes, 10% treasury, 5% burned
    final nodeShare = totalCost * 0.85;
    final treasuryShare = totalCost * 0.10;
    final burnAmount = totalCost * 0.05;

    // Split node share equally among serving nodes
    final perNodeAmount = nodeShare / servingNodes.length;

    for (final node in servingNodes) {
      await blockchain.transferPyreal(
        fromUserId: userId,
        toUserId: node.nodeId,
        amount: perNodeAmount,
        memo: 'CDN delivery: ${content.name}',
      );

      _logger.i('Paid ${node.nodeId}: $perNodeAmount ₱');
    }

    // Treasury share
    await blockchain.transferPyreal(
      fromUserId: userId,
      toUserId: 'treasury',
      amount: treasuryShare,
      memo: 'CDN treasury: ${content.name}',
    );

    // Burn share
    await blockchain.transferPyreal(
      fromUserId: userId,
      toUserId: 'burn_address',
      amount: burnAmount,
      memo: 'CDN burn: ${content.name}',
    );
  }

  /// Update content delivery statistics
  Future<void> _updateDeliveryStats(CDNContent content, CDNRegion region) async {
    // In production, this would update comprehensive statistics
    _logger.i('Updated delivery stats for ${content.name}');
  }

  /// Get node's CDN earnings and statistics
  Future<Map<String, dynamic>> getNodeStats(String nodeId) async {
    final node = _nodes[nodeId];
    if (node == null) {
      throw Exception('Node not found: $nodeId');
    }

    final fragmentsHosted = _nodeFragments[nodeId]?.length ?? 0;

    // Calculate estimated monthly earnings
    final storageReward = fragmentsHosted * 0.05 * _storageRewardPerGBMonth; // Approximate
    final estimatedDeliveryEarnings = fragmentsHosted * 0.5 * _pricePerGBStreamed * 100; // Rough estimate

    return {
      'nodeId': nodeId,
      'region': node.region.name,
      'fragmentsHosted': fragmentsHosted,
      'totalEarned': node.totalEarnedPyreal,
      'estimatedMonthlyEarnings': storageReward + estimatedDeliveryEarnings,
      'uptimePercentage': node.uptimePercentage,
      'storageCapacityGB': node.storageCapacityGB,
      'bandwidthMbps': node.bandwidthMbps,
    };
  }

  /// Get all content by owner
  List<CDNContent> getContentByOwner(String ownerId) {
    return _content.values.where((c) => c.ownerId == ownerId).toList();
  }

  /// Get network-wide CDN statistics
  Map<String, dynamic> getNetworkStats() {
    final totalContent = _content.length;
    final totalSizeGB = _content.values.map((c) => c.sizeGB).fold(0.0, (a, b) => a + b);
    final totalNodes = _nodes.length;
    final totalFragments = _nodeFragments.values.map((f) => f.length).fold(0, (a, b) => a + b);

    final nodesByRegion = _groupNodesByRegion();
    final contentByType = _groupContentByType();

    return {
      'totalContent': totalContent,
      'totalSizeGB': totalSizeGB,
      'totalNodes': totalNodes,
      'totalFragments': totalFragments,
      'nodesByRegion': nodesByRegion.map((k, v) => MapEntry(k.name, v.length)),
      'contentByType': contentByType.map((k, v) => MapEntry(k.name, v)),
      'averageUptime': _nodes.values.map((n) => n.uptimePercentage).fold(0.0, (a, b) => a + b) / max(_nodes.length, 1),
    };
  }

  /// Search for content
  List<CDNContent> searchContent({
    String? query,
    ContentType? type,
    String? ownerId,
  }) {
    var results = _content.values.toList();

    if (query != null && query.isNotEmpty) {
      results = results.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    }

    if (type != null) {
      results = results.where((c) => c.type == type).toList();
    }

    if (ownerId != null) {
      results = results.where((c) => c.ownerId == ownerId).toList();
    }

    // Sort by upload date (newest first)
    results.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return results;
  }

  // Helper methods

  Map<CDNRegion, List<CDNNode>> _groupNodesByRegion() {
    final grouped = <CDNRegion, List<CDNNode>>{};

    for (final node in _nodes.values) {
      grouped.putIfAbsent(node.region, () => []).add(node);
    }

    return grouped;
  }

  Map<ContentType, int> _groupContentByType() {
    final grouped = <ContentType, int>{};

    for (final content in _content.values) {
      grouped[content.type] = (grouped[content.type] ?? 0) + 1;
    }

    return grouped;
  }

  List<CDNRegion> _getRegionPriority(CDNRegion userRegion) {
    // Return regions in order of proximity to user
    final priority = <CDNRegion>[userRegion];

    switch (userRegion) {
      case CDNRegion.northAmericaEast:
        priority.addAll([
          CDNRegion.northAmericaWest,
          CDNRegion.europeWest,
          CDNRegion.southAmerica,
        ]);
        break;
      case CDNRegion.europeWest:
        priority.addAll([
          CDNRegion.europeEast,
          CDNRegion.northAmericaEast,
          CDNRegion.africa,
        ]);
        break;
      case CDNRegion.asiaPacific:
        priority.addAll([
          CDNRegion.oceania,
          CDNRegion.europeEast,
          CDNRegion.northAmericaWest,
        ]);
        break;
      default:
        priority.addAll(CDNRegion.values.where((r) => r != userRegion));
    }

    return priority;
  }

  double _calculateEstimatedLatency(List<CDNNode> nodes, CDNRegion userRegion) {
    if (nodes.isEmpty) return 1000.0;

    // Simplified latency calculation
    final sameRegionNodes = nodes.where((n) => n.region == userRegion).length;
    final baseLatency = sameRegionNodes > 0 ? 15.0 : 50.0; // ms

    // Factor in bandwidth
    final avgBandwidth = nodes.map((n) => n.bandwidthMbps).reduce((a, b) => a + b) / nodes.length;
    final bandwidthFactor = 100.0 / avgBandwidth; // Lower is better

    return baseLatency + bandwidthFactor;
  }

  String _generateContentId() {
    return 'cdn_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
