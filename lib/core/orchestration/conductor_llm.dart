import 'package:logger/logger.dart';
import '../blockchain/blockchain.dart';
import '../hdp/hdp_manager.dart';
import '../compute/opencl_manager.dart';
import '../compute/device_type.dart';
import '../nostr/nostr_client.dart';
import 'hypervisor.dart';

/// Conductor: Invisible distributed AI orchestrator
/// Runs as part of the hypervisor layer to intelligently manage resources
/// Learns from usage patterns and operates autonomously without user interaction
/// Uses ZK rollups for efficient decision storage
class ConductorLLM {
  final Blockchain blockchain;
  final HDPManager hdpManager;
  final OpenCLManager openclManager;
  final NostrClient nostrClient;
  final Hypervisor hypervisor;
  final Logger _logger = Logger();

  // Conductor configuration
  static const String modelName = 'TinyLlama-1.1B-Conductor';
  static const int contextSize = 2048;
  static const int maxTokens = 512;
  static const int zkRollupBatchSize = 100; // Batch 100 decisions into one rollup

  // Model state
  bool _isInitialized = false;
  bool _isInferenceRunning = false;
  String? _modelFragmentId;
  Map<String, double> _nodePerformance = {};
  List<ConductorDecision> _decisionHistory = [];
  List<ConductorDecision> _zkBatch = []; // Current ZK rollup batch

  // Usage pattern learning
  Map<String, UsagePattern> _learnedPatterns = {};
  int _totalTasksProcessed = 0;

  ConductorLLM({
    required this.blockchain,
    required this.hdpManager,
    required this.openclManager,
    required this.nostrClient,
    required this.hypervisor,
  });

  /// Initialize the Conductor LLM
  /// Loads model weights from HDP and prepares for distributed inference
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.i('🎭 Initializing Conductor LLM...');

    try {
      // Step 1: Check if model exists in HDP
      _modelFragmentId = await _loadOrCreateModel();

      // Step 2: Distribute model across compute nodes
      await _distributeModelAcrossNodes();

      // Step 3: Initialize inference pipeline
      await _initializeInferencePipeline();

      // Step 4: Record initialization on blockchain
      blockchain.addBlock({
        'type': 'conductor_initialization',
        'modelName': modelName,
        'fragmentId': _modelFragmentId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _isInitialized = true;
      _logger.i('✅ Conductor LLM initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Conductor: $e');
      rethrow;
    }
  }

  /// Autonomously analyze and schedule task (internal, called by hypervisor)
  /// Users never interact with this directly - it operates invisibly
  Future<ConductorDecision> _conductTaskInternal({
    required Map<String, dynamic> taskMetadata,
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Conductor not initialized');
    }

    if (_isInferenceRunning) {
      _logger.w('Conductor is busy, queuing request...');
      await Future.delayed(const Duration(milliseconds: 500));
      return _conductTaskInternal(
        taskMetadata: taskMetadata,
        userId: userId,
      );
    }

    _isInferenceRunning = true;

    try {
      _totalTasksProcessed++;
      final taskType = taskMetadata['taskType'] as String? ?? 'unknown';

      _logger.i('🎭 Conductor analyzing task: $taskType (invisible operation)');

      // Step 1: Analyze usage patterns for this user and task type
      final pattern = _getOrCreatePattern(userId, taskType);

      // Step 2: Run distributed inference based on learned patterns
      final analysis = await _runDistributedInference(taskMetadata, pattern);

      // Step 3: Make intelligent decision
      final decision = ConductorDecision(
        taskId: taskMetadata['taskId'] as String? ?? 'unknown',
        taskType: taskType,
        userId: userId,
        recommendedDeviceType: analysis.recommendedDevice,
        estimatedResources: analysis.estimatedResources,
        priority: analysis.priority,
        reasoning: analysis.reasoning,
        confidence: analysis.confidence,
        estimatedDuration: analysis.estimatedDuration,
        suggestedNodes: analysis.suggestedNodes,
        timestamp: DateTime.now(),
      );

      // Step 4: Add to ZK rollup batch (not individual blockchain records)
      _addToZKBatch(decision);

      // Step 5: Add to history for learning
      _decisionHistory.add(decision);
      if (_decisionHistory.length > 1000) {
        _decisionHistory.removeAt(0);
      }

      _logger.d('✨ Conductor decision (${decision.confidence.toStringAsFixed(2)}): ${decision.reasoning}');

      return decision;
    } finally {
      _isInferenceRunning = false;
    }
  }

  /// Record task outcome for learning (called after task completion)
  void recordTaskOutcome({
    required String taskId,
    required bool success,
    required Duration actualDuration,
    required double actualResources,
  }) {
    final decision = _decisionHistory.firstWhere(
      (d) => d.taskId == taskId,
      orElse: () => throw Exception('Decision not found'),
    );

    // Update usage pattern with actual results
    final patternKey = '${decision.userId}_${decision.taskType}';
    final pattern = _learnedPatterns[patternKey];

    if (pattern != null) {
      pattern.recordOutcome(
        success: success,
        predictedDevice: decision.recommendedDeviceType,
        predictedDuration: decision.estimatedDuration,
        actualDuration: actualDuration,
        predictedResources: decision.estimatedResources,
        actualResources: actualResources,
      );

      _logger.d('📊 Learning: Updated pattern for ${decision.taskType} (accuracy: ${pattern.accuracy.toStringAsFixed(2)})');
    }
  }

  /// Get metrics for dashboard (public API for hypervisor screen)
  Map<String, dynamic> getMetrics() {
    return {
      'totalDecisions': _totalTasksProcessed,
      'batchedDecisions': _zkBatch.length,
      'averageConfidence': _decisionHistory.isEmpty
          ? 0.0
          : _decisionHistory.fold<double>(0.0, (sum, d) => sum + d.confidence) / _decisionHistory.length,
      'learnedPatterns': _learnedPatterns.length,
      'nodePerformance': _nodePerformance,
      'recentDecisions': _decisionHistory.take(10).map((d) => {
        'taskId': d.taskId,
        'taskType': d.taskType,
        'device': d.recommendedDeviceType.name,
        'confidence': d.confidence,
        'timestamp': d.timestamp.toIso8601String(),
      }).toList(),
    };
  }

  /// Get detailed reasoning for a specific decision (for drill-down)
  Map<String, dynamic>? getDecisionReasoning(String taskId) {
    try {
      final decision = _decisionHistory.firstWhere((d) => d.taskId == taskId);
      return {
        'taskId': decision.taskId,
        'taskType': decision.taskType,
        'userId': decision.userId,
        'device': decision.recommendedDeviceType.name,
        'resources': decision.estimatedResources,
        'priority': decision.priority,
        'duration': decision.estimatedDuration.inSeconds,
        'reasoning': decision.reasoning,
        'confidence': decision.confidence,
        'suggestedNodes': decision.suggestedNodes,
        'timestamp': decision.timestamp.toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Get Conductor statistics
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'inferenceRunning': _isInferenceRunning,
      'modelName': modelName,
      'decisionsCount': _decisionHistory.length,
      'averageConfidence': _decisionHistory.isEmpty
          ? 0.0
          : _decisionHistory.fold<double>(
              0.0, (sum, d) => sum + d.confidence) / _decisionHistory.length,
      'nodePerformance': _nodePerformance,
    };
  }

  // =========================================================================
  // PRIVATE METHODS - ZK Rollup & Pattern Learning
  // =========================================================================

  /// Add decision to ZK rollup batch
  void _addToZKBatch(ConductorDecision decision) {
    _zkBatch.add(decision);

    // When batch is full, commit to blockchain as ZK rollup
    if (_zkBatch.length >= zkRollupBatchSize) {
      _commitZKRollup();
    }
  }

  /// Commit ZK rollup batch to blockchain
  void _commitZKRollup() {
    if (_zkBatch.isEmpty) return;

    _logger.i('📦 Committing ZK rollup: ${_zkBatch.length} decisions');

    // Create merkle root of all decisions in batch
    final merkleRoot = _computeMerkleRoot(_zkBatch);

    // Create summary stats for the batch
    final summary = {
      'decisionsCount': _zkBatch.length,
      'merkleRoot': merkleRoot,
      'averageConfidence': _zkBatch.fold<double>(0.0, (sum, d) => sum + d.confidence) / _zkBatch.length,
      'deviceDistribution': _computeDeviceDistribution(_zkBatch),
      'timeRange': {
        'start': _zkBatch.first.timestamp.toIso8601String(),
        'end': _zkBatch.last.timestamp.toIso8601String(),
      },
    };

    // Store only the rollup summary on blockchain (not individual decisions)
    blockchain.addBlock({
      'type': 'conductor_zk_rollup',
      'batch': summary,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('✅ ZK rollup committed. Saved ${(_zkBatch.length - 1)} blockchain writes!');

    // Clear batch
    _zkBatch.clear();
  }

  /// Compute merkle root for ZK proof
  String _computeMerkleRoot(List<ConductorDecision> decisions) {
    // Simple hash-based merkle root (production would use proper ZK circuits)
    final hashes = decisions.map((d) => d.taskId.hashCode.toString()).toList();
    return hashes.fold<int>(0, (sum, h) => sum + int.parse(h)).toString();
  }

  /// Compute device distribution for summary
  Map<String, int> _computeDeviceDistribution(List<ConductorDecision> decisions) {
    final distribution = <String, int>{};
    for (final decision in decisions) {
      final device = decision.recommendedDeviceType.name;
      distribution[device] = (distribution[device] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get or create usage pattern for user+taskType
  UsagePattern _getOrCreatePattern(String userId, String taskType) {
    final key = '${userId}_$taskType';

    if (!_learnedPatterns.containsKey(key)) {
      _learnedPatterns[key] = UsagePattern(
        userId: userId,
        taskType: taskType,
      );
      _logger.d('📚 Created new usage pattern: $key');
    }

    return _learnedPatterns[key]!;
  }

  // =========================================================================
  // PRIVATE METHODS - Distributed LLM Implementation
  // =========================================================================

  Future<String> _loadOrCreateModel() async {
    _logger.i('📦 Loading Conductor model from HDP...');

    // In production, this would load actual model weights
    // For now, we simulate by creating a fragment ID
    final modelData = 'TinyLlama-1.1B-Conductor-Quantized-Q4'.codeUnits;
    final fragmentId = await hdpManager.encodeData(modelData);

    _logger.i('✓ Model loaded: $fragmentId');
    return fragmentId;
  }

  Future<void> _distributeModelAcrossNodes() async {
    _logger.i('🌐 Distributing model across compute nodes...');

    final devices = openclManager.getStats()['devices'] as List;

    for (final device in devices) {
      final deviceMap = device as Map<String, dynamic>;
      final nodeId = deviceMap['name'] as String;

      // Simulate distributing model shards to each node
      _nodePerformance[nodeId] = 1.0;
      _logger.i('  ✓ Node $nodeId ready');
    }

    // Broadcast availability via NOSTR
    await nostrClient.publishEvent(
      kind: 30078, // Custom application event
      content: 'Conductor model distributed and ready',
      tags: [
        ['model', modelName],
        ['nodes', _nodePerformance.length.toString()],
      ],
    );
  }

  Future<void> _initializeInferencePipeline() async {
    _logger.i('⚙️ Initializing inference pipeline...');

    // Set up pipeline parallelism across nodes
    // Each node gets a layer of the model
    await Future.delayed(const Duration(milliseconds: 100));

    _logger.i('✓ Pipeline ready for inference');
  }

  Future<TaskAnalysis> _runDistributedInference(
    Map<String, dynamic> metadata,
    UsagePattern pattern,
  ) async {
    _logger.d('🧠 Running distributed inference (invisible)...');

    // Simulate distributed LLM inference
    // In production, this would:
    // 1. Encode task metadata as tokens
    // 2. Distribute tokens across nodes via NOSTR
    // 3. Each node processes its layers
    // 4. Aggregate results based on learned patterns
    // 5. Generate optimized decision

    // Use pattern-based intelligence with learned history
    final analysis = await _analyzeTaskIntelligently(metadata, pattern);

    // Simulate inference latency based on network size
    final nodeCount = _nodePerformance.length.clamp(1, 10);
    final latencyMs = 50 + (100 / nodeCount);
    await Future.delayed(Duration(milliseconds: latencyMs.toInt()));

    // Update node performance metrics
    for (final node in _nodePerformance.keys) {
      _nodePerformance[node] = (_nodePerformance[node]! * 0.95) + 0.05;
    }

    return analysis;
  }

  Future<TaskAnalysis> _analyzeTaskIntelligently(
    Map<String, dynamic> metadata,
    UsagePattern pattern,
  ) async {
    // Intelligent analysis based on learned usage patterns
    final taskType = metadata['taskType'] as String? ?? 'unknown';
    final lowerType = taskType.toLowerCase();

    // Analyze device requirements
    DeviceType recommendedDevice;
    double estimatedResources;
    int priority;
    Duration estimatedDuration;
    String reasoning;
    double confidence;

    // First, check if we have learned patterns for this task type
    if (pattern.hasLearned && pattern.accuracy > 0.7) {
      // Use learned pattern
      recommendedDevice = pattern.preferredDevice;
      estimatedResources = pattern.averageResources;
      estimatedDuration = Duration(seconds: pattern.averageDuration.toInt());
      priority = pattern.averagePriority;
      confidence = pattern.accuracy;
      reasoning = 'Based on ${pattern.executionCount} previous executions. Learned pattern shows ${(pattern.accuracy * 100).toStringAsFixed(1)}% accuracy.';

      _logger.d('🎓 Using learned pattern (${pattern.executionCount} runs, ${(pattern.accuracy * 100).toStringAsFixed(1)}% accuracy)');
    }
    // ML/AI tasks
    else if (lowerType.contains('ai') ||
        lowerType.contains('ml') ||
        lowerType.contains('inference') ||
        lowerType.contains('training') ||
        lowerType.contains('neural')) {
      recommendedDevice = DeviceType.gpu;
      estimatedResources = 50.0;
      priority = 3;
      estimatedDuration = const Duration(minutes: 5);
      reasoning = 'AI/ML workload detected. GPU acceleration recommended for neural network operations. High priority for compute-intensive tasks.';
      confidence = 0.85; // Lower initial confidence, will improve with learning
    }
    // Video processing
    else if (lowerType.contains('video') ||
        lowerType.contains('encode') ||
        lowerType.contains('decode') ||
        lowerType.contains('transcode')) {
      recommendedDevice = DeviceType.videoProcessor;
      estimatedResources = 30.0;
      priority = 2;
      estimatedDuration = const Duration(minutes: 10);
      reasoning = 'Video processing detected. Using dedicated video encoder/decoder hardware for optimal performance and power efficiency.';
      confidence = 0.88;
    }
    // Image processing
    else if (lowerType.contains('image') ||
        lowerType.contains('photo') ||
        lowerType.contains('render')) {
      recommendedDevice = DeviceType.isp;
      estimatedResources = 20.0;
      priority = 2;
      estimatedDuration = const Duration(minutes: 2);
      reasoning = 'Image processing task. ISP (Image Signal Processor) provides hardware-accelerated image operations.';
      confidence = 0.80;
    }
    // Signal processing
    else if (lowerType.contains('audio') ||
        lowerType.contains('signal') ||
        lowerType.contains('dsp')) {
      recommendedDevice = DeviceType.dsp;
      estimatedResources = 15.0;
      priority = 2;
      estimatedDuration = const Duration(seconds: 30);
      reasoning = 'Signal processing workload. DSP optimized for real-time audio and signal operations.';
      confidence = 0.82;
    }
    // Heavy compute
    else if (lowerType.contains('compute') ||
        lowerType.contains('calculate') ||
        lowerType.contains('simulation')) {
      recommendedDevice = DeviceType.gpu;
      estimatedResources = 40.0;
      priority = 2;
      estimatedDuration = const Duration(minutes: 8);
      reasoning = 'Compute-intensive task. GPU parallel processing provides best performance for numerical calculations.';
      confidence = 0.83;
    }
    // General tasks
    else {
      recommendedDevice = DeviceType.cpu;
      estimatedResources = 10.0;
      priority = 1;
      estimatedDuration = const Duration(minutes: 1);
      reasoning = 'General purpose task. CPU provides good balance of performance and availability.';
      confidence = 0.75;
    }

    // Learn from historical decisions for this task type
    final similarTasks = _decisionHistory.where((d) => d.taskType == taskType);

    if (similarTasks.isNotEmpty && similarTasks.length > 5) {
      // Adjust based on past performance
      confidence = (confidence + 0.95) / 2; // Increase confidence
      reasoning += ' (Informed by ${similarTasks.length} previous executions)';
    }

    // Select best nodes based on performance
    final sortedNodes = _nodePerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final suggestedNodes = sortedNodes.take(3).map((e) => e.key).toList();

    return TaskAnalysis(
      recommendedDevice: recommendedDevice,
      estimatedResources: estimatedResources,
      priority: priority,
      reasoning: reasoning,
      confidence: confidence,
      estimatedDuration: estimatedDuration,
      suggestedNodes: suggestedNodes,
    );
  }

  /// Dispose resources and flush ZK rollup batch
  void dispose() {
    // Commit any remaining decisions in ZK batch
    if (_zkBatch.isNotEmpty) {
      _commitZKRollup();
    }


    _isInitialized = false;
    _isInferenceRunning = false;
    _logger.i('🎭 Conductor LLM disposed');
  }
}

/// Task analysis result from Conductor
class TaskAnalysis {
  final DeviceType recommendedDevice;
  final double estimatedResources;
  final int priority;
  final String reasoning;
  final double confidence;
  final Duration estimatedDuration;
  final List<String> suggestedNodes;

  TaskAnalysis({
    required this.recommendedDevice,
    required this.estimatedResources,
    required this.priority,
    required this.reasoning,
    required this.confidence,
    required this.estimatedDuration,
    required this.suggestedNodes,
  });
}

/// Decision made by the Conductor (invisible orchestration)
class ConductorDecision {
  final String taskId;
  final String taskType;
  final String userId;
  final DeviceType recommendedDeviceType;
  final double estimatedResources;
  final int priority;
  final String reasoning;
  final double confidence;
  final Duration estimatedDuration;
  final List<String> suggestedNodes;
  final DateTime timestamp;

  ConductorDecision({
    required this.taskId,
    required this.taskType,
    required this.userId,
    required this.recommendedDeviceType,
    required this.estimatedResources,
    required this.priority,
    required this.reasoning,
    required this.confidence,
    required this.estimatedDuration,
    required this.suggestedNodes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskType': taskType,
        'userId': userId,
        'recommendedDeviceType': recommendedDeviceType.name,
        'estimatedResources': estimatedResources,
        'priority': priority,
        'reasoning': reasoning,
        'confidence': confidence,
        'estimatedDuration': estimatedDuration.inSeconds,
        'suggestedNodes': suggestedNodes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ConductorDecision.fromJson(Map<String, dynamic> json) {
    return ConductorDecision(
      taskId: json['taskId'] as String,
      taskType: json['taskType'] as String,
      userId: json['userId'] as String,
      recommendedDeviceType: DeviceType.values.firstWhere(
        (e) => e.name == json['recommendedDeviceType'],
      ),
      estimatedResources: (json['estimatedResources'] as num).toDouble(),
      priority: json['priority'] as int,
      reasoning: json['reasoning'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      estimatedDuration: Duration(seconds: json['estimatedDuration'] as int),
      suggestedNodes: (json['suggestedNodes'] as List).cast<String>(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Usage Pattern - Learned behavior for a user+taskType combination
class UsagePattern {
  final String userId;
  final String taskType;

  // Learned metrics
  DeviceType preferredDevice = DeviceType.cpu;
  double averageResources = 10.0;
  double averageDuration = 60.0;  // seconds
  int averagePriority = 1;
  double accuracy = 0.0;
  int executionCount = 0;
  int successCount = 0;

  // Tracking for accuracy calculation
  final List<double> _resourceErrors = [];
  final List<double> _durationErrors = [];

  UsagePattern({
    required this.userId,
    required this.taskType,
  });

  /// Check if we have enough data to use learned patterns
  bool get hasLearned => executionCount >= 3 && accuracy > 0.5;

  /// Record actual task outcome for learning
  void recordOutcome({
    required bool success,
    required DeviceType predictedDevice,
    required Duration predictedDuration,
    required Duration actualDuration,
    required double predictedResources,
    required double actualResources,
  }) {
    executionCount++;

    if (success) {
      successCount++;

      // Update preferred device if this is successful
      preferredDevice = predictedDevice;

      // Calculate errors
      final resourceError = (predictedResources - actualResources).abs() / actualResources.clamp(0.1, double.infinity);
      final durationError = (predictedDuration.inSeconds - actualDuration.inSeconds).abs() / actualDuration.inSeconds.clamp(1, double.infinity);

      _resourceErrors.add(resourceError);
      _durationErrors.add(durationError);

      // Keep last 20 errors
      if (_resourceErrors.length > 20) {
        _resourceErrors.removeAt(0);
        _durationErrors.removeAt(0);
      }

      // Update averages with exponential moving average
      final alpha = 0.3;  // Weight for new data
      averageResources = (alpha * actualResources) + ((1 - alpha) * averageResources);
      averageDuration = (alpha * actualDuration.inSeconds) + ((1 - alpha) * averageDuration);

      // Calculate accuracy (1.0 - average error)
      final avgResourceError = _resourceErrors.fold<double>(0.0, (sum, e) => sum + e) / _resourceErrors.length;
      final avgDurationError = _durationErrors.fold<double>(0.0, (sum, e) => sum + e) / _durationErrors.length;
      accuracy = (1.0 - ((avgResourceError + avgDurationError) / 2)).clamp(0.0, 1.0);
    }
  }
}
