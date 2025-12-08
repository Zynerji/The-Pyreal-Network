import 'device_type.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'opencl_manager.dart';

/// Distributed compute network for sharing resources across nodes
class ComputeNetwork {
  final OpenCLManager openclManager;
  final Logger _logger = Logger();

  final List<ComputeNode> _nodes = [];
  final Map<String, ComputeTask> _tasks = {};
  bool _isActive = false;

  ComputeNetwork({required this.openclManager});

  /// Join the compute network
  Future<void> join({
    required String nodeId,
    required int maxConcurrentTasks,
    required List<DeviceType> allowedDevices,
  }) async {
    _logger.i('Joining compute network as node: $nodeId');

    final localNode = ComputeNode(
      id: nodeId,
      address: 'local',
      devices: openclManager.getDevices(),
      isLocal: true,
      maxConcurrentTasks: maxConcurrentTasks,
      currentTasks: 0,
    );

    _nodes.add(localNode);
    _isActive = true;

    await openclManager.startComputeSharing(
      maxConcurrentTasks: maxConcurrentTasks,
      allowedDevices: allowedDevices,
    );

    _logger.i('Joined compute network with ${_nodes.length} nodes');
  }

  /// Leave the compute network
  void leave() {
    _logger.i('Leaving compute network');
    openclManager.stopComputeSharing();
    _isActive = false;
  }

  /// Add a remote node to the network
  void addNode(ComputeNode node) {
    if (!_nodes.any((n) => n.id == node.id)) {
      _nodes.add(node);
      _logger.i('Added node: ${node.id}');
    }
  }

  /// Remove a node from the network
  void removeNode(String nodeId) {
    _nodes.removeWhere((n) => n.id == nodeId);
    _logger.i('Removed node: $nodeId');
  }

  /// Submit a distributed compute task
  Future<ComputeTask> submitDistributedTask({
    required String kernelSource,
    required Map<String, dynamic> inputs,
    DeviceType? preferredDevice,
  }) async {
    if (!_isActive) {
      throw Exception('Not connected to compute network');
    }

    final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

    // Find best node for the task
    final node = _selectNode(preferredDevice);

    if (node == null) {
      throw Exception('No available nodes for task execution');
    }

    _logger.i('Assigning task $taskId to node ${node.id}');

    final task = await openclManager.submitTask(
      taskId: taskId,
      kernelSource: kernelSource,
      inputs: inputs,
      preferredDevice: preferredDevice,
    );

    _tasks[taskId] = task;

    return task;
  }

  /// Select best node for task execution
  ComputeNode? _selectNode(DeviceType? preferredDevice) {
    if (_nodes.isEmpty) return null;

    // Filter available nodes
    final availableNodes = _nodes.where(
      (n) => n.currentTasks < n.maxConcurrentTasks,
    ).toList();

    if (availableNodes.isEmpty) return null;

    // If preferred device type, try to find matching node
    if (preferredDevice != null) {
      final matchingNodes = availableNodes.where(
        (n) => n.devices.any((d) => d.type == preferredDevice),
      ).toList();

      if (matchingNodes.isNotEmpty) {
        return matchingNodes.first;
      }
    }

    // Return node with least current tasks
    availableNodes.sort((a, b) => a.currentTasks.compareTo(b.currentTasks));
    return availableNodes.first;
  }

  /// Get task status
  ComputeTask? getTask(String taskId) => _tasks[taskId];

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    final totalDevices = _nodes.fold<int>(
      0,
      (sum, node) => sum + node.devices.length,
    );

    final totalTasks = _tasks.length;
    final completedTasks = _tasks.values.where(
      (t) => t.status == TaskStatus.completed,
    ).length;

    return {
      'isActive': _isActive,
      'nodeCount': _nodes.length,
      'totalDevices': totalDevices,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'pendingTasks': totalTasks - completedTasks,
      'nodes': _nodes.map((n) => n.toJson()).toList(),
    };
  }

  /// Dispose resources
  void dispose() {
    leave();
    _nodes.clear();
    _tasks.clear();
  }
}

/// Represents a node in the compute network
class ComputeNode {
  final String id;
  final String address;
  final List<ComputeDevice> devices;
  final bool isLocal;
  final int maxConcurrentTasks;
  int currentTasks;

  ComputeNode({
    required this.id,
    required this.address,
    required this.devices,
    this.isLocal = false,
    required this.maxConcurrentTasks,
    this.currentTasks = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'address': address,
    'devices': devices.map((d) => d.toJson()).toList(),
    'isLocal': isLocal,
    'maxConcurrentTasks': maxConcurrentTasks,
    'currentTasks': currentTasks,
  };

  @override
  String toString() => 'ComputeNode($id: ${devices.length} devices)';
}
