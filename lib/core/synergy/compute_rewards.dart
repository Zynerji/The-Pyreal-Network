import '../compute/device_type.dart';
import '../blockchain/blockchain.dart';
import '../tokens/app_token.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// Compute rewards system: Earn tokens by sharing compute power
/// Synergy: Token minting + Compute tasks = Self-sustaining economy
class ComputeRewardsSystem {
  final Blockchain blockchain;
  final Logger _logger = Logger();

  // Reward rates per compute unit per hour
  static const Map<DeviceType, double> _rewardRates = {
    DeviceType.cpu: 1.0,
    DeviceType.gpu: 5.0,
    DeviceType.accelerator: 3.0,
  };

  ComputeRewardsSystem({required this.blockchain});

  /// Record compute contribution and calculate reward
  Future<ComputeReward> recordContribution({
    required String userId,
    required String deviceId,
    required DeviceType deviceType,
    required Duration computeTime,
    required String taskId,
    required Map<String, dynamic> taskMetadata,
  }) async {
    // Calculate reward based on device type and time
    final baseReward = _calculateReward(deviceType, computeTime);

    // Bonus for specialized devices
    final bonus = _calculateBonus(deviceType, taskMetadata);

    final totalReward = baseReward + bonus;

    // Record on blockchain
    blockchain.addBlock({
      'type': 'compute_contribution',
      'userId': userId,
      'deviceId': deviceId,
      'deviceType': deviceType.name,
      'taskId': taskId,
      'computeTime': computeTime.inSeconds,
      'baseReward': baseReward,
      'bonus': bonus,
      'totalReward': totalReward,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Recorded compute contribution: $totalReward tokens for $userId');

    return ComputeReward(
      userId: userId,
      deviceType: deviceType,
      computeTime: computeTime,
      baseReward: baseReward,
      bonus: bonus,
      totalReward: totalReward,
      taskId: taskId,
    );
  }

  /// Calculate base reward
  double _calculateReward(DeviceType deviceType, Duration computeTime) {
    final ratePerHour = _rewardRates[deviceType] ?? 1.0;
    final hours = computeTime.inSeconds / 3600.0;
    return ratePerHour * hours;
  }

  /// Calculate bonus rewards for specialized tasks
  double _calculateBonus(DeviceType deviceType, Map<String, dynamic> metadata) {
    double bonus = 0.0;

    // Bonus for ML tasks on NPU
    if (metadata['taskType'] == 'ml' && deviceType.toString().contains('npu')) {
      bonus += 2.0;
    }

    // Bonus for HDP encoding on GPU
    if (metadata['taskType'] == 'hdpEncoding' && deviceType == DeviceType.gpu) {
      bonus += 1.5;
    }

    // Bonus for long-running tasks
    if (metadata.containsKey('priority') && metadata['priority'] == 'high') {
      bonus += 1.0;
    }

    return bonus;
  }

  /// Get total rewards for a user
  Future<double> getTotalRewards(String userId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'compute_contribution' && data['userId'] == userId);

    return blocks.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['totalReward'] as num).toDouble(),
    );
  }

  /// Mint reward token for user
  Future<AppToken> mintRewardToken({
    required String userId,
    required double rewardAmount,
  }) async {
    final tokenId = const Uuid().v4();

    final token = AppToken(
      id: tokenId,
      name: 'Compute Reward Token',
      type: AppTokenType.custom,
      url: '',
      credentials: {
        'type': 'reward',
        'amount': rewardAmount,
        'earnedBy': 'compute_sharing',
      },
      iconPath: 'assets/images/reward.png',
      mintedAt: DateTime.now(),
      userId: userId,
      metadata: {
        'rewardAmount': rewardAmount,
        'tokenType': 'PYREAL',
      },
    );

    // Record on blockchain
    blockchain.addBlock({
      'type': 'reward_token_mint',
      'tokenId': tokenId,
      'userId': userId,
      'amount': rewardAmount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Minted reward token: $rewardAmount PYREAL for $userId');

    return token;
  }

  /// Get compute statistics for user
  Future<ComputeStats> getStats(String userId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'compute_contribution' && data['userId'] == userId);

    final totalTasks = blocks.length;
    final totalTime = blocks.fold<int>(
      0,
      (sum, block) => sum + (block.data['computeTime'] as int),
    );
    final totalRewards = await getTotalRewards(userId);

    return ComputeStats(
      userId: userId,
      totalTasks: totalTasks,
      totalComputeTime: Duration(seconds: totalTime),
      totalRewards: totalRewards,
      averageRewardPerTask: totalTasks > 0 ? totalRewards / totalTasks : 0.0,
    );
  }
}

/// Compute reward record
class ComputeReward {
  final String userId;
  final DeviceType deviceType;
  final Duration computeTime;
  final double baseReward;
  final double bonus;
  final double totalReward;
  final String taskId;

  ComputeReward({
    required this.userId,
    required this.deviceType,
    required this.computeTime,
    required this.baseReward,
    required this.bonus,
    required this.totalReward,
    required this.taskId,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'deviceType': deviceType.name,
    'computeTime': computeTime.inSeconds,
    'baseReward': baseReward,
    'bonus': bonus,
    'totalReward': totalReward,
    'taskId': taskId,
  };
}

/// Compute statistics for user
class ComputeStats {
  final String userId;
  final int totalTasks;
  final Duration totalComputeTime;
  final double totalRewards;
  final double averageRewardPerTask;

  ComputeStats({
    required this.userId,
    required this.totalTasks,
    required this.totalComputeTime,
    required this.totalRewards,
    required this.averageRewardPerTask,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalTasks': totalTasks,
    'totalComputeTime': totalComputeTime.inSeconds,
    'totalRewards': totalRewards,
    'averageRewardPerTask': averageRewardPerTask,
  };
}
