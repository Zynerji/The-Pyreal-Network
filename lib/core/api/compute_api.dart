import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../blockchain/blockchain.dart';
import '../compute/opencl_manager.dart';
import '../compute/compute_network.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// API token system for external customers to access compute resources
/// Allows monetization of the compute network
class ComputeAPISystem {
  final Blockchain blockchain;
  final ComputeNetwork computeNetwork;
  final Logger _logger = Logger();

  // Pricing tiers (PYREAL tokens per compute unit-hour)
  static const Map<ComputeTier, double> _pricing = {
    ComputeTier.free: 0.0,
    ComputeTier.basic: 1.0,
    ComputeTier.professional: 0.8, // Discount for volume
    ComputeTier.enterprise: 0.6,   // Best rate
  };

  ComputeAPISystem({
    required this.blockchain,
    required this.computeNetwork,
  });

  /// Generate API token for external customer
  Future<APIToken> generateAPIToken({
    required String customerId,
    required String customerName,
    required ComputeTier tier,
    required double creditBalance,
    Map<String, dynamic>? limits,
  }) async {
    final tokenId = const Uuid().v4();
    final apiKey = _generateAPIKey();
    final secretKey = _generateSecretKey();

    final token = APIToken(
      id: tokenId,
      customerId: customerId,
      customerName: customerName,
      apiKey: apiKey,
      secretKeyHash: _hashSecret(secretKey),
      tier: tier,
      creditBalance: creditBalance,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      limits: limits ?? _getDefaultLimits(tier),
      isActive: true,
      usage: APIUsage.empty(),
    );

    // Record on blockchain
    blockchain.addBlock({
      'type': 'api_token_creation',
      'tokenId': tokenId,
      'customerId': customerId,
      'tier': tier.name,
      'creditBalance': creditBalance,
      'createdAt': token.createdAt.toIso8601String(),
    });

    _logger.i('Generated API token for $customerName (${tier.name})');

    return token;
  }

  /// Submit compute task via API
  Future<APITaskResult> submitTask({
    required String apiKey,
    required String secretKey,
    required Map<String, dynamic> taskRequest,
  }) async {
    // Validate API credentials
    final token = await _validateCredentials(apiKey, secretKey);
    if (token == null) {
      throw APIException('Invalid API credentials');
    }

    if (!token.isActive) {
      throw APIException('API token is not active');
    }

    // Check credit balance
    final estimatedCost = _estimateTaskCost(taskRequest, token.tier);
    if (token.creditBalance < estimatedCost) {
      throw APIException('Insufficient credits. Need $estimatedCost, have ${token.creditBalance}');
    }

    // Check rate limits
    if (!_checkRateLimits(token)) {
      throw APIException('Rate limit exceeded');
    }

    // Submit to compute network
    final task = await computeNetwork.submitDistributedTask(
      kernelSource: taskRequest['kernelSource'] as String,
      inputs: taskRequest['inputs'] as Map<String, dynamic>,
      preferredDevice: _parseDeviceType(taskRequest['deviceType']),
    );

    // Deduct credits
    final actualCost = _calculateActualCost(task, token.tier);
    await _deductCredits(token.id, actualCost);

    // Record usage
    await _recordUsage(token.id, task, actualCost);

    _logger.i('API task submitted: ${task.id} for ${token.customerName}');

    return APITaskResult(
      taskId: task.id,
      status: task.status,
      cost: actualCost,
      remainingCredits: token.creditBalance - actualCost,
    );
  }

  /// Add credits to API token
  Future<void> addCredits({
    required String tokenId,
    required double amount,
    required String paymentReference,
  }) async {
    blockchain.addBlock({
      'type': 'api_credit_purchase',
      'tokenId': tokenId,
      'amount': amount,
      'paymentReference': paymentReference,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Added $amount credits to token $tokenId');
  }

  /// Get API token statistics
  Future<Map<String, dynamic>> getTokenStats(String tokenId) async {
    final usageBlocks = blockchain.searchBlocks((data) =>
        data['type'] == 'api_task_usage' && data['tokenId'] == tokenId);

    final totalTasks = usageBlocks.length;
    final totalCost = usageBlocks.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['cost'] as num).toDouble(),
    );

    final totalComputeTime = usageBlocks.fold<int>(
      0,
      (sum, block) => sum + (block.data['computeTimeSeconds'] as int? ?? 0),
    );

    return {
      'tokenId': tokenId,
      'totalTasks': totalTasks,
      'totalCost': totalCost,
      'totalComputeTime': totalComputeTime,
      'averageCostPerTask': totalTasks > 0 ? totalCost / totalTasks : 0.0,
    };
  }

  String _generateAPIKey() {
    final uuid = const Uuid().v4();
    return 'pyreal_${uuid.replaceAll('-', '')}';
  }

  String _generateSecretKey() {
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(bytes);
  }

  String _hashSecret(String secret) {
    return sha256.convert(utf8.encode(secret)).toString();
  }

  Future<APIToken?> _validateCredentials(String apiKey, String secretKey) async {
    // In production, lookup from database
    // For demo, validate against blockchain
    return null; // Simplified
  }

  double _estimateTaskCost(Map<String, dynamic> request, ComputeTier tier) {
    final estimatedTime = request['estimatedTimeSeconds'] as int? ?? 60;
    final computeUnits = request['computeUnits'] as int? ?? 1;
    final rate = _pricing[tier] ?? 1.0;

    return (estimatedTime / 3600.0) * computeUnits * rate;
  }

  double _calculateActualCost(ComputeTask task, ComputeTier tier) {
    final actualTime = DateTime.now().difference(task.submittedAt).inSeconds;
    final rate = _pricing[tier] ?? 1.0;

    return (actualTime / 3600.0) * rate;
  }

  bool _checkRateLimits(APIToken token) {
    final limits = token.limits;
    final requestsPerMinute = limits['requestsPerMinute'] as int? ?? 60;

    // Check recent usage (simplified)
    return true;
  }

  Future<void> _deductCredits(String tokenId, double amount) async {
    blockchain.addBlock({
      'type': 'api_credit_deduction',
      'tokenId': tokenId,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _recordUsage(String tokenId, ComputeTask task, double cost) async {
    blockchain.addBlock({
      'type': 'api_task_usage',
      'tokenId': tokenId,
      'taskId': task.id,
      'cost': cost,
      'computeTimeSeconds': DateTime.now().difference(task.submittedAt).inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  DeviceType? _parseDeviceType(dynamic deviceType) {
    if (deviceType == null) return null;
    return DeviceType.values.firstWhere(
      (t) => t.name == deviceType,
      orElse: () => DeviceType.cpu,
    );
  }

  Map<String, dynamic> _getDefaultLimits(ComputeTier tier) {
    switch (tier) {
      case ComputeTier.free:
        return {
          'requestsPerMinute': 10,
          'maxConcurrentTasks': 1,
          'maxTaskDuration': 60,
        };
      case ComputeTier.basic:
        return {
          'requestsPerMinute': 60,
          'maxConcurrentTasks': 5,
          'maxTaskDuration': 300,
        };
      case ComputeTier.professional:
        return {
          'requestsPerMinute': 300,
          'maxConcurrentTasks': 20,
          'maxTaskDuration': 1800,
        };
      case ComputeTier.enterprise:
        return {
          'requestsPerMinute': 1000,
          'maxConcurrentTasks': 100,
          'maxTaskDuration': 7200,
        };
    }
  }
}

/// API Token model
class APIToken {
  final String id;
  final String customerId;
  final String customerName;
  final String apiKey;
  final String secretKeyHash;
  final ComputeTier tier;
  final double creditBalance;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic> limits;
  final bool isActive;
  final APIUsage usage;

  APIToken({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.apiKey,
    required this.secretKeyHash,
    required this.tier,
    required this.creditBalance,
    required this.createdAt,
    required this.expiresAt,
    required this.limits,
    required this.isActive,
    required this.usage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'apiKey': apiKey,
    'tier': tier.name,
    'creditBalance': creditBalance,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'limits': limits,
    'isActive': isActive,
  };
}

/// Compute tiers for pricing
enum ComputeTier {
  free,
  basic,
  professional,
  enterprise,
}

/// API usage tracking
class APIUsage {
  final int totalRequests;
  final double totalCost;
  final int totalComputeTime;

  APIUsage({
    required this.totalRequests,
    required this.totalCost,
    required this.totalComputeTime,
  });

  factory APIUsage.empty() {
    return APIUsage(
      totalRequests: 0,
      totalCost: 0.0,
      totalComputeTime: 0,
    );
  }
}

/// API task result
class APITaskResult {
  final String taskId;
  final TaskStatus status;
  final double cost;
  final double remainingCredits;

  APITaskResult({
    required this.taskId,
    required this.status,
    required this.cost,
    required this.remainingCredits,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'status': status.name,
    'cost': cost,
    'remainingCredits': remainingCredits,
  };
}

class APIException implements Exception {
  final String message;
  APIException(this.message);

  @override
  String toString() => 'APIException: $message';
}
