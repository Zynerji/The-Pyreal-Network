import 'dart:async';
import 'dart:math';
import '../blockchain/blockchain.dart';
import '../orchestration/conductor.dart';
import 'package:logger/logger.dart';

/// Types of data that oracles can provide
enum OracleDataType {
  cryptoPrices,      // Every 10 seconds
  stockPrices,       // Every 1 minute
  sportsScores,      // Real-time
  weatherData,       // Every 15 minutes
  iotSensors,        // Real-time
  socialMetrics,     // Every 5 minutes
  commodityPrices,   // Every 1 minute
  forexRates,        // Every 30 seconds
  nftFloorPrices,    // Every 1 minute
  gasEstimates,      // Real-time
}

/// Oracle node registration info
class OracleNode {
  final String nodeId;
  final Set<OracleDataType> supportedDataTypes;
  final double uptimePercentage;
  final int totalRequestsFulfilled;
  final double accuracyScore;
  final double totalEarnedPyreal;
  final DateTime registeredAt;

  const OracleNode({
    required this.nodeId,
    required this.supportedDataTypes,
    this.uptimePercentage = 99.0,
    this.totalRequestsFulfilled = 0,
    this.accuracyScore = 100.0,
    this.totalEarnedPyreal = 0.0,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'supportedDataTypes': supportedDataTypes.map((t) => t.name).toList(),
        'uptimePercentage': uptimePercentage,
        'totalRequestsFulfilled': totalRequestsFulfilled,
        'accuracyScore': accuracyScore,
        'totalEarnedPyreal': totalEarnedPyreal,
        'registeredAt': registeredAt.toIso8601String(),
      };
}

/// Data source for oracle nodes to fetch from
enum DataSource {
  coinbase,
  binance,
  kraken,
  yahooFinance,
  alphaVantage,
  openWeather,
  espnApi,
  coingecko,
  chainlink,
  custom,
}

/// Oracle data response from a single node
class OracleDataResponse {
  final String nodeId;
  final String requestId;
  final dynamic value;
  final DataSource source;
  final DateTime timestamp;
  final double confidence; // 0-100

  const OracleDataResponse({
    required this.nodeId,
    required this.requestId,
    required this.value,
    required this.source,
    required this.timestamp,
    this.confidence = 100.0,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'requestId': requestId,
        'value': value,
        'source': source.name,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
      };
}

/// Aggregated oracle response with consensus
class AggregatedOracleResponse {
  final String requestId;
  final OracleDataType dataType;
  final String query;
  final dynamic consensusValue;
  final double consensusConfidence;
  final int nodesResponded;
  final List<OracleDataResponse> individualResponses;
  final DateTime timestamp;
  final String validationMethod;

  const AggregatedOracleResponse({
    required this.requestId,
    required this.dataType,
    required this.query,
    required this.consensusValue,
    required this.consensusConfidence,
    required this.nodesResponded,
    required this.individualResponses,
    required this.timestamp,
    required this.validationMethod,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'dataType': dataType.name,
        'query': query,
        'consensusValue': consensusValue,
        'consensusConfidence': consensusConfidence,
        'nodesResponded': nodesResponded,
        'individualResponses': individualResponses.map((r) => r.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'validationMethod': validationMethod,
      };
}

/// Oracle request from smart contract or user
class OracleRequest {
  final String requestId;
  final String requesterId;
  final OracleDataType dataType;
  final String query;
  final DateTime requestedAt;
  final double feePyreal;
  final int requiredNodes;
  final Duration timeout;

  bool fulfilled;
  AggregatedOracleResponse? response;

  OracleRequest({
    required this.requestId,
    required this.requesterId,
    required this.dataType,
    required this.query,
    required this.requestedAt,
    required this.feePyreal,
    this.requiredNodes = 20,
    this.timeout = const Duration(seconds: 30),
    this.fulfilled = false,
    this.response,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'requesterId': requesterId,
        'dataType': dataType.name,
        'query': query,
        'requestedAt': requestedAt.toIso8601String(),
        'feePyreal': feePyreal,
        'requiredNodes': requiredNodes,
        'fulfilled': fulfilled,
        'response': response?.toJson(),
      };
}

/// Decentralized Oracle Network
class OracleNetwork {
  final Blockchain blockchain;
  final Conductor conductor;
  final Logger _logger = Logger();

  final Map<String, OracleNode> _nodes = {};
  final Map<String, OracleRequest> _requests = {};
  final Map<String, List<OracleDataResponse>> _pendingResponses = {};

  // Pricing by data type (in PYREAL)
  static const Map<OracleDataType, double> _dataTypePricing = {
    OracleDataType.cryptoPrices: 0.5,
    OracleDataType.stockPrices: 1.0,
    OracleDataType.sportsScores: 0.8,
    OracleDataType.weatherData: 0.5,
    OracleDataType.iotSensors: 1.5,
    OracleDataType.socialMetrics: 0.7,
    OracleDataType.commodityPrices: 1.0,
    OracleDataType.forexRates: 0.8,
    OracleDataType.nftFloorPrices: 1.2,
    OracleDataType.gasEstimates: 0.5,
  };

  OracleNetwork({
    required this.blockchain,
    required this.conductor,
  });

  /// Register a node as oracle provider
  Future<OracleNode> registerOracleNode({
    required String nodeId,
    required Set<OracleDataType> supportedDataTypes,
  }) async {
    _logger.i('Registering oracle node: $nodeId supporting ${supportedDataTypes.length} data types');

    if (supportedDataTypes.isEmpty) {
      throw Exception('Node must support at least one data type');
    }

    final node = OracleNode(
      nodeId: nodeId,
      supportedDataTypes: supportedDataTypes,
      registeredAt: DateTime.now(),
    );

    _nodes[nodeId] = node;

    _logger.i('Oracle node registered: $nodeId');

    return node;
  }

  /// Request data from oracle network
  Future<AggregatedOracleResponse> requestData({
    required String requesterId,
    required OracleDataType dataType,
    required String query,
    int requiredNodes = 20,
  }) async {
    final requestId = _generateRequestId();
    final fee = _dataTypePricing[dataType] ?? 1.0;

    _logger.i('Oracle request: $query ($dataType) - $fee ₱');

    // Verify requester has sufficient balance
    final balance = await blockchain.getBalance(requesterId);
    if (balance < fee) {
      throw Exception('Insufficient balance: $balance ₱ < $fee ₱');
    }

    // Find capable nodes
    final capableNodes = _nodes.values
        .where((n) => n.supportedDataTypes.contains(dataType))
        .toList();

    if (capableNodes.length < requiredNodes) {
      throw Exception('Insufficient oracle nodes: ${capableNodes.length} < $requiredNodes');
    }

    // Select best nodes by accuracy and uptime
    capableNodes.sort((a, b) {
      final scoreA = a.accuracyScore * a.uptimePercentage;
      final scoreB = b.accuracyScore * b.uptimePercentage;
      return scoreB.compareTo(scoreA);
    });

    final selectedNodes = capableNodes.take(requiredNodes).toList();

    final request = OracleRequest(
      requestId: requestId,
      requesterId: requesterId,
      dataType: dataType,
      query: query,
      requestedAt: DateTime.now(),
      feePyreal: fee,
      requiredNodes: requiredNodes,
    );

    _requests[requestId] = request;
    _pendingResponses[requestId] = [];

    // Broadcast request to selected nodes
    await _broadcastRequest(request, selectedNodes);

    // Collect responses (simulated)
    final responses = await _collectResponses(request, selectedNodes);

    // Aggregate and validate responses
    final aggregated = await _aggregateResponses(request, responses);

    request.fulfilled = true;
    request.response = aggregated;

    // Distribute payment to oracle nodes
    await _distributeOraclePayment(request, selectedNodes);

    _logger.i('Oracle request fulfilled: $query = ${aggregated.consensusValue} (${aggregated.consensusConfidence.toStringAsFixed(1)}% confidence)');

    return aggregated;
  }

  /// Broadcast request to oracle nodes
  Future<void> _broadcastRequest(OracleRequest request, List<OracleNode> nodes) async {
    _logger.i('Broadcasting oracle request to ${nodes.length} nodes');

    // In production, this would use Conductor to broadcast to network
    for (final node in nodes) {
      _logger.d('Notifying oracle node: ${node.nodeId}');
    }
  }

  /// Collect responses from oracle nodes
  Future<List<OracleDataResponse>> _collectResponses(
    OracleRequest request,
    List<OracleNode> nodes,
  ) async {
    _logger.i('Collecting responses from ${nodes.length} oracle nodes');

    final responses = <OracleDataResponse>[];

    // Simulate nodes fetching data from various sources
    for (final node in nodes) {
      final response = await _simulateNodeResponse(request, node);
      responses.add(response);
      _pendingResponses[request.requestId]!.add(response);
    }

    _logger.i('Collected ${responses.length} responses');

    return responses;
  }

  /// Simulate a node fetching data (in production, nodes would make actual API calls)
  Future<OracleDataResponse> _simulateNodeResponse(
    OracleRequest request,
    OracleNode node,
  ) async {
    // Simulate network latency
    await Future.delayed(Duration(milliseconds: Random().nextInt(500) + 100));

    dynamic value;
    DataSource source;

    // Simulate different data types
    switch (request.dataType) {
      case OracleDataType.cryptoPrices:
        // Simulate Bitcoin price with slight variance
        value = 43250.0 + (Random().nextDouble() - 0.5) * 10;
        source = [DataSource.coinbase, DataSource.binance, DataSource.kraken][Random().nextInt(3)];
        break;

      case OracleDataType.stockPrices:
        // Simulate stock price
        value = 150.0 + (Random().nextDouble() - 0.5) * 2;
        source = DataSource.yahooFinance;
        break;

      case OracleDataType.weatherData:
        // Simulate temperature in Celsius
        value = 20.0 + (Random().nextDouble() - 0.5) * 5;
        source = DataSource.openWeather;
        break;

      case OracleDataType.sportsScores:
        // Simulate game score
        value = {'home': Random().nextInt(5), 'away': Random().nextInt(5)};
        source = DataSource.espnApi;
        break;

      default:
        value = Random().nextDouble() * 100;
        source = DataSource.custom;
    }

    return OracleDataResponse(
      nodeId: node.nodeId,
      requestId: request.requestId,
      value: value,
      source: source,
      timestamp: DateTime.now(),
      confidence: 95.0 + Random().nextDouble() * 5.0, // 95-100% confidence
    );
  }

  /// Aggregate responses using consensus mechanism
  Future<AggregatedOracleResponse> _aggregateResponses(
    OracleRequest request,
    List<OracleDataResponse> responses,
  ) async {
    if (responses.isEmpty) {
      throw Exception('No oracle responses received');
    }

    _logger.i('Aggregating ${responses.length} oracle responses');

    dynamic consensusValue;
    double consensusConfidence;
    String validationMethod;

    // Different aggregation strategies based on data type
    if (request.dataType == OracleDataType.cryptoPrices ||
        request.dataType == OracleDataType.stockPrices ||
        request.dataType == OracleDataType.weatherData) {
      // Numeric data: use median and calculate confidence from variance
      final values = responses.map((r) => r.value as double).toList()..sort();
      consensusValue = _calculateMedian(values);

      // Calculate variance
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
      final stdDev = sqrt(variance);
      final coefficientOfVariation = stdDev / mean;

      // Confidence inversely proportional to variation
      consensusConfidence = (1 - coefficientOfVariation.clamp(0.0, 0.1) * 10) * 100;
      validationMethod = 'median_with_variance';

      _logger.i('Numeric consensus: $consensusValue ± ${stdDev.toStringAsFixed(2)} (CV: ${(coefficientOfVariation * 100).toStringAsFixed(2)}%)');
    } else {
      // Non-numeric data: use majority voting
      final valueCounts = <String, int>{};

      for (final response in responses) {
        final key = response.value.toString();
        valueCounts[key] = (valueCounts[key] ?? 0) + 1;
      }

      // Find most common value
      final sortedValues = valueCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      consensusValue = sortedValues.first.key;
      consensusConfidence = (sortedValues.first.value / responses.length) * 100;
      validationMethod = 'majority_voting';

      _logger.i('Categorical consensus: $consensusValue with ${sortedValues.first.value}/${responses.length} votes');
    }

    // Flag outlier nodes with significantly different responses
    await _flagOutliers(responses, consensusValue);

    return AggregatedOracleResponse(
      requestId: request.requestId,
      dataType: request.dataType,
      query: request.query,
      consensusValue: consensusValue,
      consensusConfidence: consensusConfidence,
      nodesResponded: responses.length,
      individualResponses: responses,
      timestamp: DateTime.now(),
      validationMethod: validationMethod,
    );
  }

  /// Identify and penalize outlier nodes
  Future<void> _flagOutliers(List<OracleDataResponse> responses, dynamic consensusValue) async {
    if (consensusValue is! double) return;

    final threshold = consensusValue * 0.05; // 5% deviation threshold

    for (final response in responses) {
      if (response.value is double) {
        final deviation = (response.value as double - consensusValue).abs();

        if (deviation > threshold) {
          // Penalize outlier node
          final node = _nodes[response.nodeId];
          if (node != null) {
            final penalizedScore = node.accuracyScore * 0.95; // 5% penalty
            _nodes[response.nodeId] = OracleNode(
              nodeId: node.nodeId,
              supportedDataTypes: node.supportedDataTypes,
              uptimePercentage: node.uptimePercentage,
              totalRequestsFulfilled: node.totalRequestsFulfilled,
              accuracyScore: penalizedScore,
              totalEarnedPyreal: node.totalEarnedPyreal,
              registeredAt: node.registeredAt,
            );

            _logger.w('Outlier detected: ${response.nodeId} (deviation: ${deviation.toStringAsFixed(2)})');
          }
        }
      }
    }
  }

  /// Distribute payment to oracle nodes
  Future<void> _distributeOraclePayment(
    OracleRequest request,
    List<OracleNode> nodes,
  ) async {
    // Revenue split: 90% to oracle nodes, 10% to treasury
    final nodeShare = request.feePyreal * 0.90;
    final treasuryShare = request.feePyreal * 0.10;

    final perNodeAmount = nodeShare / nodes.length;

    for (final node in nodes) {
      await blockchain.transferPyreal(
        fromUserId: request.requesterId,
        toUserId: node.nodeId,
        amount: perNodeAmount,
        memo: 'Oracle response: ${request.requestId}',
      );

      // Update node stats
      final updatedNode = OracleNode(
        nodeId: node.nodeId,
        supportedDataTypes: node.supportedDataTypes,
        uptimePercentage: node.uptimePercentage,
        totalRequestsFulfilled: node.totalRequestsFulfilled + 1,
        accuracyScore: node.accuracyScore,
        totalEarnedPyreal: node.totalEarnedPyreal + perNodeAmount,
        registeredAt: node.registeredAt,
      );

      _nodes[node.nodeId] = updatedNode;
    }

    // Treasury share
    await blockchain.transferPyreal(
      fromUserId: request.requesterId,
      toUserId: 'treasury',
      amount: treasuryShare,
      memo: 'Oracle treasury: ${request.requestId}',
    );

    _logger.i('Distributed $nodeShare ₱ to ${nodes.length} oracle nodes ($perNodeAmount ₱ each)');
  }

  /// Get node statistics
  Future<Map<String, dynamic>> getNodeStats(String nodeId) async {
    final node = _nodes[nodeId];
    if (node == null) {
      throw Exception('Oracle node not found: $nodeId');
    }

    // Calculate estimated daily earnings based on request volume
    final requestsPerDay = _requests.length * (1440 / 60); // Rough estimate
    final avgFee = _dataTypePricing.values.reduce((a, b) => a + b) / _dataTypePricing.length;
    final estimatedDailyEarnings = (requestsPerDay / _nodes.length) * avgFee * 0.90;

    return {
      'nodeId': nodeId,
      'supportedDataTypes': node.supportedDataTypes.map((t) => t.name).toList(),
      'uptimePercentage': node.uptimePercentage,
      'accuracyScore': node.accuracyScore,
      'totalRequestsFulfilled': node.totalRequestsFulfilled,
      'totalEarnedPyreal': node.totalEarnedPyreal,
      'estimatedDailyEarnings': estimatedDailyEarnings,
      'registeredAt': node.registeredAt.toIso8601String(),
    };
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    final totalNodes = _nodes.length;
    final totalRequests = _requests.length;
    final fulfilledRequests = _requests.values.where((r) => r.fulfilled).length;

    final dataTypeDistribution = <OracleDataType, int>{};
    for (final request in _requests.values) {
      dataTypeDistribution[request.dataType] = (dataTypeDistribution[request.dataType] ?? 0) + 1;
    }

    final totalFeesCollected = _requests.values.map((r) => r.feePyreal).fold(0.0, (a, b) => a + b);

    return {
      'totalNodes': totalNodes,
      'totalRequests': totalRequests,
      'fulfilledRequests': fulfilledRequests,
      'fulfillmentRate': totalRequests > 0 ? fulfilledRequests / totalRequests : 0.0,
      'dataTypeDistribution': dataTypeDistribution.map((k, v) => MapEntry(k.name, v)),
      'totalFeesCollected': totalFeesCollected,
      'averageNodeAccuracy': _nodes.values.map((n) => n.accuracyScore).fold(0.0, (a, b) => a + b) / max(_nodes.length, 1),
      'averageNodeUptime': _nodes.values.map((n) => n.uptimePercentage).fold(0.0, (a, b) => a + b) / max(_nodes.length, 1),
    };
  }

  /// Get request history
  List<OracleRequest> getRequestHistory({
    String? requesterId,
    OracleDataType? dataType,
    bool? fulfilled,
  }) {
    var requests = _requests.values.toList();

    if (requesterId != null) {
      requests = requests.where((r) => r.requesterId == requesterId).toList();
    }

    if (dataType != null) {
      requests = requests.where((r) => r.dataType == dataType).toList();
    }

    if (fulfilled != null) {
      requests = requests.where((r) => r.fulfilled == fulfilled).toList();
    }

    // Sort by most recent first
    requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    return requests;
  }

  // Helper methods

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;

    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  String _generateRequestId() {
    return 'oracle_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
