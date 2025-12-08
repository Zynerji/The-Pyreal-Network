import '../compute/opencl_manager.dart';
import '../compute/compute_network.dart';
import '../blockchain/blockchain.dart';
import 'package:logger/logger.dart';

/// Hypervisor - Lightweight orchestrator running on shared compute
/// Manages resources, schedules tasks, and ensures fair allocation
class ComputeHypervisor {
  final ComputeNetwork computeNetwork;
  final Blockchain blockchain;
  final Logger _logger = Logger();

  // Hypervisor state
  final Map<String, TaskAllocation> _allocations = {};
  final Map<String, ResourceQuota> _quotas = {};
  bool _isRunning = false;

  ComputeHypervisor({
    required this.computeNetwork,
    required this.blockchain,
  });

  /// Start the hypervisor
  Future<void> start() async {
    if (_isRunning) return;

    _logger.i('Starting Compute Hypervisor...');

    // Initialize resource monitoring
    await _initializeMonitoring();

    _isRunning = true;

    // Start orchestration loop
    _orchestrationLoop();

    _logger.i('Compute Hypervisor started');
  }

  /// Stop the hypervisor
  void stop() {
    _isRunning = false;
    _logger.i('Compute Hypervisor stopped');
  }

  /// Allocate resources for a task
  Future<TaskAllocation> allocate({
    required String taskId,
    required String userId,
    required ResourceRequirements requirements,
    required TaskPriority priority,
  }) async {
    // Check user quota
    final quota = _getOrCreateQuota(userId);

    if (!quota.canAllocate(requirements)) {
      throw HypervisorException('User quota exceeded');
    }

    // Find optimal device
    final device = await _selectOptimalDevice(requirements, priority);

    if (device == null) {
      throw HypervisorException('No suitable device available');
    }

    // Create allocation
    final allocation = TaskAllocation(
      taskId: taskId,
      userId: userId,
      deviceId: device.id,
      requirements: requirements,
      priority: priority,
      allocatedAt: DateTime.now(),
      status: AllocationStatus.allocated,
    );

    _allocations[taskId] = allocation;

    // Update quota
    quota.allocate(requirements);

    // Record on blockchain
    blockchain.addBlock({
      'type': 'hypervisor_allocation',
      'taskId': taskId,
      'userId': userId,
      'deviceId': device.id,
      'priority': priority.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Allocated ${device.name} for task $taskId (${priority.name})');

    return allocation;
  }

  /// Release allocated resources
  Future<void> release(String taskId) async {
    final allocation = _allocations.remove(taskId);

    if (allocation != null) {
      final quota = _quotas[allocation.userId];
      quota?.release(allocation.requirements);

      blockchain.addBlock({
        'type': 'hypervisor_release',
        'taskId': taskId,
        'userId': allocation.userId,
        'duration': DateTime.now().difference(allocation.allocatedAt).inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('Released resources for task $taskId');
    }
  }

  /// Get hypervisor statistics
  Map<String, dynamic> getStats() {
    final totalAllocations = _allocations.length;
    final deviceUtilization = _calculateDeviceUtilization();

    return {
      'isRunning': _isRunning,
      'activeAllocations': totalAllocations,
      'totalUsers': _quotas.length,
      'deviceUtilization': deviceUtilization,
      'allocations': _allocations.values.map((a) => a.toJson()).toList(),
    };
  }

  /// Set user quota
  void setQuota(String userId, ResourceQuota quota) {
    _quotas[userId] = quota;
    _logger.i('Set quota for $userId: ${quota.maxComputeUnits} CUs');
  }

  Future<void> _initializeMonitoring() async {
    // Initialize device monitoring
    _logger.d('Initializing resource monitoring...');
  }

  void _orchestrationLoop() {
    // Lightweight event loop for resource management
    Future.doWhile(() async {
      if (!_isRunning) return false;

      // Check for stuck tasks
      await _checkStuckTasks();

      // Rebalance if needed
      await _rebalanceResources();

      // Wait before next iteration
      await Future.delayed(const Duration(seconds: 5));

      return _isRunning;
    });
  }

  Future<void> _checkStuckTasks() async {
    final now = DateTime.now();

    for (final allocation in _allocations.values.toList()) {
      final duration = now.difference(allocation.allocatedAt);

      // Tasks stuck for > 1 hour get terminated
      if (duration.inHours >= 1) {
        _logger.w('Task ${allocation.taskId} stuck for ${duration.inHours}h, releasing...');
        await release(allocation.taskId);
      }
    }
  }

  Future<void> _rebalanceResources() async {
    // Rebalance resources if needed (simplified)
    final utilization = _calculateDeviceUtilization();

    if (utilization > 0.9) {
      _logger.w('High utilization ($utilization), may need to scale');
    }
  }

  Future<ComputeDevice?> _selectOptimalDevice(
    ResourceRequirements requirements,
    TaskPriority priority,
  ) async {
    final stats = computeNetwork.getNetworkStats();
    final nodes = stats['nodes'] as List<dynamic>? ?? [];

    // Find least loaded device matching requirements
    ComputeDevice? bestDevice;
    int minLoad = 999999;

    for (final nodeData in nodes) {
      final node = nodeData as Map<String, dynamic>;
      final devices = node['devices'] as List<dynamic>? ?? [];

      for (final deviceData in devices) {
        final device = deviceData as ComputeDevice;

        if (_meetsRequirements(device, requirements)) {
          final load = _calculateDeviceLoad(device.id);

          if (load < minLoad) {
            minLoad = load;
            bestDevice = device;
          }
        }
      }
    }

    return bestDevice;
  }

  bool _meetsRequirements(ComputeDevice device, ResourceRequirements req) {
    return device.computeUnits >= req.computeUnits &&
           device.globalMemorySize >= req.memoryMB * 1024 * 1024;
  }

  int _calculateDeviceLoad(String deviceId) {
    return _allocations.values.where((a) => a.deviceId == deviceId).length;
  }

  double _calculateDeviceUtilization() {
    final stats = computeNetwork.getNetworkStats();
    final totalDevices = stats['totalDevices'] as int? ?? 1;
    final activeAllocations = _allocations.length;

    return activeAllocations / totalDevices;
  }

  ResourceQuota _getOrCreateQuota(String userId) {
    return _quotas.putIfAbsent(
      userId,
      () => ResourceQuota.standard(),
    );
  }
}

/// Task allocation record
class TaskAllocation {
  final String taskId;
  final String userId;
  final String deviceId;
  final ResourceRequirements requirements;
  final TaskPriority priority;
  final DateTime allocatedAt;
  final AllocationStatus status;

  TaskAllocation({
    required this.taskId,
    required this.userId,
    required this.deviceId,
    required this.requirements,
    required this.priority,
    required this.allocatedAt,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'userId': userId,
    'deviceId': deviceId,
    'requirements': requirements.toJson(),
    'priority': priority.name,
    'allocatedAt': allocatedAt.toIso8601String(),
    'status': status.name,
  };
}

/// Resource requirements for a task
class ResourceRequirements {
  final int computeUnits;
  final int memoryMB;
  final int estimatedTimeSeconds;

  ResourceRequirements({
    required this.computeUnits,
    required this.memoryMB,
    required this.estimatedTimeSeconds,
  });

  Map<String, dynamic> toJson() => {
    'computeUnits': computeUnits,
    'memoryMB': memoryMB,
    'estimatedTimeSeconds': estimatedTimeSeconds,
  };
}

/// Resource quota for a user
class ResourceQuota {
  final int maxComputeUnits;
  final int maxMemoryMB;
  final int maxConcurrentTasks;

  int _usedComputeUnits = 0;
  int _usedMemoryMB = 0;
  int _activeTasks = 0;

  ResourceQuota({
    required this.maxComputeUnits,
    required this.maxMemoryMB,
    required this.maxConcurrentTasks,
  });

  factory ResourceQuota.standard() {
    return ResourceQuota(
      maxComputeUnits: 10,
      maxMemoryMB: 4096,
      maxConcurrentTasks: 5,
    );
  }

  factory ResourceQuota.premium() {
    return ResourceQuota(
      maxComputeUnits: 100,
      maxMemoryMB: 16384,
      maxConcurrentTasks: 20,
    );
  }

  bool canAllocate(ResourceRequirements req) {
    return _usedComputeUnits + req.computeUnits <= maxComputeUnits &&
           _usedMemoryMB + req.memoryMB <= maxMemoryMB &&
           _activeTasks < maxConcurrentTasks;
  }

  void allocate(ResourceRequirements req) {
    _usedComputeUnits += req.computeUnits;
    _usedMemoryMB += req.memoryMB;
    _activeTasks++;
  }

  void release(ResourceRequirements req) {
    _usedComputeUnits -= req.computeUnits;
    _usedMemoryMB -= req.memoryMB;
    _activeTasks--;
  }
}

enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

enum AllocationStatus {
  allocated,
  running,
  completed,
  failed,
}

class HypervisorException implements Exception {
  final String message;
  HypervisorException(this.message);

  @override
  String toString() => 'HypervisorException: $message';
}
