import '../compute/device_type.dart';

/// Types of productive tasks that can be performed during idle time
enum IdleTaskType {
  /// Run NOSTR relay services (0.5-2 ₱/hour)
  nostrRelay,

  /// Store holographic data partitions for other users (0.3-1.5 ₱/hour)
  hdpStorage,

  /// Collaborative AI model training (2-8 ₱/hour equivalent when model sells)
  aiModelTraining,

  /// Serve external inference API requests (5-20 ₱/hour)
  externalInferenceAPI,

  /// Blockchain services: archive, indexing, validation (3-12 ₱/hour)
  blockchainServices,

  /// Scientific computing contribution (0.1-0.5 ₱/hour + 2x reputation)
  scientificCompute,

  /// Generate AI content for marketplace (variable, split on sale)
  contentGeneration,

  /// Video transcoding service (external revenue)
  videoTranscode,

  /// 3D render farm (external revenue)
  renderFarm,

  /// Pre-compute likely queries for instant delivery (variable)
  speculativeCache,
}

/// Revenue model for idle tasks
class IdleTaskRevenue {
  final double minPyrealPerHour;
  final double maxPyrealPerHour;
  final double reputationMultiplier;
  final Map<String, double> revenueDistribution;

  const IdleTaskRevenue({
    required this.minPyrealPerHour,
    required this.maxPyrealPerHour,
    this.reputationMultiplier = 1.0,
    required this.revenueDistribution,
  });

  double get averageRevenue => (minPyrealPerHour + maxPyrealPerHour) / 2;

  static const Map<IdleTaskType, IdleTaskRevenue> revenueModels = {
    IdleTaskType.nostrRelay: IdleTaskRevenue(
      minPyrealPerHour: 0.5,
      maxPyrealPerHour: 2.0,
      revenueDistribution: {'provider': 0.80, 'treasury': 0.15, 'burned': 0.05},
    ),
    IdleTaskType.hdpStorage: IdleTaskRevenue(
      minPyrealPerHour: 0.3,
      maxPyrealPerHour: 1.5,
      revenueDistribution: {'provider': 0.85, 'treasury': 0.10, 'burned': 0.05},
    ),
    IdleTaskType.aiModelTraining: IdleTaskRevenue(
      minPyrealPerHour: 2.0,
      maxPyrealPerHour: 8.0,
      revenueDistribution: {'trainers': 0.60, 'treasury': 0.30, 'development': 0.10},
    ),
    IdleTaskType.externalInferenceAPI: IdleTaskRevenue(
      minPyrealPerHour: 5.0,
      maxPyrealPerHour: 20.0,
      revenueDistribution: {'provider': 0.70, 'treasury': 0.20, 'burned': 0.10},
    ),
    IdleTaskType.blockchainServices: IdleTaskRevenue(
      minPyrealPerHour: 3.0,
      maxPyrealPerHour: 12.0,
      revenueDistribution: {'provider': 0.80, 'treasury': 0.15, 'burned': 0.05},
    ),
    IdleTaskType.scientificCompute: IdleTaskRevenue(
      minPyrealPerHour: 0.1,
      maxPyrealPerHour: 0.5,
      reputationMultiplier: 2.0,
      revenueDistribution: {'provider': 0.70, 'treasury': 0.20, 'research': 0.10},
    ),
    IdleTaskType.contentGeneration: IdleTaskRevenue(
      minPyrealPerHour: 1.0,
      maxPyrealPerHour: 6.0,
      revenueDistribution: {'generator': 0.60, 'treasury': 0.40},
    ),
    IdleTaskType.videoTranscode: IdleTaskRevenue(
      minPyrealPerHour: 2.0,
      maxPyrealPerHour: 8.0,
      revenueDistribution: {'provider': 0.75, 'treasury': 0.20, 'burned': 0.05},
    ),
    IdleTaskType.renderFarm: IdleTaskRevenue(
      minPyrealPerHour: 4.0,
      maxPyrealPerHour: 15.0,
      revenueDistribution: {'provider': 0.75, 'treasury': 0.20, 'burned': 0.05},
    ),
    IdleTaskType.speculativeCache: IdleTaskRevenue(
      minPyrealPerHour: 0.5,
      maxPyrealPerHour: 3.0,
      revenueDistribution: {'provider': 0.80, 'treasury': 0.20},
    ),
  };
}

/// Device capabilities for idle task assignment
class DeviceCapabilities {
  final DeviceType type;
  final double computeUnits;
  final double memoryGB;
  final bool hasGPU;
  final bool hasNPU;
  final double networkBandwidthMbps;

  const DeviceCapabilities({
    required this.type,
    required this.computeUnits,
    required this.memoryGB,
    required this.hasGPU,
    required this.hasNPU,
    required this.networkBandwidthMbps,
  });

  /// Check if device is suitable for a specific idle task
  bool isSuitableFor(IdleTaskType taskType) {
    switch (taskType) {
      case IdleTaskType.aiModelTraining:
        return hasGPU && computeUnits >= 20.0 && memoryGB >= 8.0;
      case IdleTaskType.externalInferenceAPI:
        return (hasGPU || hasNPU) && computeUnits >= 10.0;
      case IdleTaskType.renderFarm:
        return hasGPU && computeUnits >= 15.0 && memoryGB >= 4.0;
      case IdleTaskType.videoTranscode:
        return computeUnits >= 10.0 && memoryGB >= 4.0;
      case IdleTaskType.blockchainServices:
        return computeUnits >= 5.0 && networkBandwidthMbps >= 10.0;
      case IdleTaskType.nostrRelay:
        return networkBandwidthMbps >= 5.0;
      case IdleTaskType.hdpStorage:
        return memoryGB >= 2.0 && networkBandwidthMbps >= 5.0;
      case IdleTaskType.scientificCompute:
        return computeUnits >= 5.0;
      case IdleTaskType.contentGeneration:
        return (hasGPU || hasNPU) && computeUnits >= 5.0;
      case IdleTaskType.speculativeCache:
        return computeUnits >= 3.0 && memoryGB >= 2.0;
    }
  }
}

/// User preferences for idle compute
class UserIdlePreferences {
  final bool allowCryptoMining;
  final bool allowExternalAPI;
  final bool allowScientificCompute;
  final bool allowBlockchainServices;
  final List<IdleTaskType> optOutTasks;
  final double minRevenuePyrealPerHour;

  const UserIdlePreferences({
    this.allowCryptoMining = false,  // Default to opt-out
    this.allowExternalAPI = true,
    this.allowScientificCompute = true,
    this.allowBlockchainServices = true,
    this.optOutTasks = const [],
    this.minRevenuePyrealPerHour = 0.0,
  });

  bool isAllowed(IdleTaskType taskType) {
    if (optOutTasks.contains(taskType)) return false;

    switch (taskType) {
      case IdleTaskType.externalInferenceAPI:
        return allowExternalAPI;
      case IdleTaskType.blockchainServices:
        return allowBlockchainServices;
      case IdleTaskType.scientificCompute:
        return allowScientificCompute;
      default:
        return true;
    }
  }
}

/// Idle task assignment with scoring
class IdleTaskAssignment {
  final IdleTaskType taskType;
  final double score;
  final double estimatedRevenuePyrealPerHour;
  final double networkSynergyScore;
  final String reasoning;
  final DeviceType assignedDevice;
  final DateTime timestamp;

  const IdleTaskAssignment({
    required this.taskType,
    required this.score,
    required this.estimatedRevenuePyrealPerHour,
    required this.networkSynergyScore,
    required this.reasoning,
    required this.assignedDevice,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'taskType': taskType.name,
    'score': score,
    'estimatedRevenue': estimatedRevenuePyrealPerHour,
    'synergyScore': networkSynergyScore,
    'reasoning': reasoning,
    'device': assignedDevice.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Idle compute statistics
class IdleComputeStats {
  final int totalIdleTasksAssigned;
  final double totalPyrealEarnedFromIdle;
  final double averageIdleUtilization;
  final Map<IdleTaskType, int> taskDistribution;
  final Map<IdleTaskType, double> revenueByTaskType;
  final double currentIdlePercentage;

  const IdleComputeStats({
    required this.totalIdleTasksAssigned,
    required this.totalPyrealEarnedFromIdle,
    required this.averageIdleUtilization,
    required this.taskDistribution,
    required this.revenueByTaskType,
    required this.currentIdlePercentage,
  });

  Map<String, dynamic> toJson() => {
    'totalIdleTasks': totalIdleTasksAssigned,
    'totalEarned': totalPyrealEarnedFromIdle,
    'avgUtilization': averageIdleUtilization,
    'taskDistribution': taskDistribution.map((k, v) => MapEntry(k.name, v)),
    'revenueByType': revenueByTaskType.map((k, v) => MapEntry(k.name, v)),
    'currentIdle': currentIdlePercentage,
  };
}
