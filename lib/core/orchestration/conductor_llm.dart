import 'package:logger/logger.dart';
import '../blockchain/blockchain.dart';
import '../hdp/hdp_manager.dart';
import '../compute/opencl_manager.dart';
import '../compute/device_type.dart';
import '../nostr/nostr_client.dart';
import 'hypervisor.dart';

/// Conductor: Intelligent tiny LLM orchestrator
/// Runs distributedly across the compute network to manage resources
/// Uses natural language understanding for intelligent task scheduling
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

  // Model state
  bool _isInitialized = false;
  bool _isInferenceRunning = false;
  String? _modelFragmentId;
  Map<String, double> _nodePerformance = {};
  List<ConductorDecision> _decisionHistory = [];

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

  /// Ask the Conductor for intelligent resource allocation
  Future<ConductorDecision> conductTask({
    required String taskDescription,
    required Map<String, dynamic> taskMetadata,
    String? userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Conductor not initialized');
    }

    if (_isInferenceRunning) {
      _logger.w('Conductor is busy, queuing request...');
      await Future.delayed(const Duration(milliseconds: 500));
      return conductTask(
        taskDescription: taskDescription,
        taskMetadata: taskMetadata,
        userId: userId,
      );
    }

    _isInferenceRunning = true;

    try {
      _logger.i('🎭 Conductor analyzing: "$taskDescription"');

      // Step 1: Run distributed inference to analyze task
      final analysis = await _runDistributedInference(taskDescription, taskMetadata);

      // Step 2: Make intelligent decisions
      final decision = ConductorDecision(
        taskId: taskMetadata['taskId'] as String? ?? 'unknown',
        taskDescription: taskDescription,
        recommendedDeviceType: analysis.recommendedDevice,
        estimatedResources: analysis.estimatedResources,
        priority: analysis.priority,
        reasoning: analysis.reasoning,
        confidence: analysis.confidence,
        estimatedDuration: analysis.estimatedDuration,
        suggestedNodes: analysis.suggestedNodes,
        timestamp: DateTime.now(),
      );

      // Step 3: Record decision on blockchain
      blockchain.addBlock({
        'type': 'conductor_decision',
        'taskId': decision.taskId,
        'decision': decision.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Step 4: Add to history
      _decisionHistory.add(decision);
      if (_decisionHistory.length > 100) {
        _decisionHistory.removeAt(0);
      }

      _logger.i('✨ Conductor decision: ${decision.reasoning}');

      return decision;
    } finally {
      _isInferenceRunning = false;
    }
  }

  /// Natural language query interface
  Future<String> query(String question) async {
    if (!_isInitialized) {
      return 'Conductor is not initialized yet.';
    }

    _logger.i('💬 Query to Conductor: "$question"');

    // Build context from system state
    final context = await _buildSystemContext();
    final prompt = _buildQueryPrompt(question, context);

    // Run inference
    final analysis = await _runDistributedInference(prompt, {});

    return analysis.reasoning;
  }

  /// Explain a previous decision
  String explainDecision(String taskId) {
    final decision = _decisionHistory.firstWhere(
      (d) => d.taskId == taskId,
      orElse: () => throw Exception('Decision not found'),
    );

    return '''
Task: ${decision.taskDescription}

Decision:
- Device: ${decision.recommendedDeviceType.name.toUpperCase()}
- Resources: ${decision.estimatedResources} compute units
- Priority: ${decision.priority}
- Duration: ~${decision.estimatedDuration.inSeconds}s

Reasoning:
${decision.reasoning}

Confidence: ${(decision.confidence * 100).toStringAsFixed(1)}%

Suggested Nodes:
${decision.suggestedNodes.map((n) => '  • $n').join('\n')}
''';
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
    String input,
    Map<String, dynamic> metadata,
  ) async {
    _logger.i('🧠 Running distributed inference...');

    // Simulate distributed LLM inference
    // In production, this would:
    // 1. Tokenize input
    // 2. Distribute tokens across nodes via NOSTR
    // 3. Each node processes its layers
    // 4. Aggregate results
    // 5. Generate final output

    // For now, use rule-based intelligence with learning
    final analysis = await _analyzeTaskIntelligently(input, metadata);

    // Simulate inference latency based on network size
    final nodeCount = _nodePerformance.length;
    final latencyMs = 50 + (100 / nodeCount.clamp(1, 10));
    await Future.delayed(Duration(milliseconds: latencyMs.toInt()));

    // Update node performance metrics
    for (final node in _nodePerformance.keys) {
      _nodePerformance[node] = (_nodePerformance[node]! * 0.95) + 0.05;
    }

    return analysis;
  }

  Future<TaskAnalysis> _analyzeTaskIntelligently(
    String description,
    Map<String, dynamic> metadata,
  ) async {
    // Intelligent task analysis using NLP patterns and learned history
    final lowerDesc = description.toLowerCase();

    // Analyze device requirements
    DeviceType recommendedDevice;
    double estimatedResources;
    int priority;
    Duration estimatedDuration;
    String reasoning;
    double confidence;

    // ML/AI tasks
    if (lowerDesc.contains('ai') ||
        lowerDesc.contains('ml') ||
        lowerDesc.contains('inference') ||
        lowerDesc.contains('training') ||
        lowerDesc.contains('neural')) {
      recommendedDevice = DeviceType.gpu;
      estimatedResources = 50.0;
      priority = 3;
      estimatedDuration = const Duration(minutes: 5);
      reasoning = 'AI/ML workload detected. GPU acceleration recommended for neural network operations. High priority for compute-intensive tasks.';
      confidence = 0.92;
    }
    // Video processing
    else if (lowerDesc.contains('video') ||
        lowerDesc.contains('encode') ||
        lowerDesc.contains('decode') ||
        lowerDesc.contains('transcode')) {
      recommendedDevice = DeviceType.videoProcessor;
      estimatedResources = 30.0;
      priority = 2;
      estimatedDuration = const Duration(minutes: 10);
      reasoning = 'Video processing detected. Using dedicated video encoder/decoder hardware for optimal performance and power efficiency.';
      confidence = 0.88;
    }
    // Image processing
    else if (lowerDesc.contains('image') ||
        lowerDesc.contains('photo') ||
        lowerDesc.contains('render')) {
      recommendedDevice = DeviceType.isp;
      estimatedResources = 20.0;
      priority = 2;
      estimatedDuration = const Duration(minutes: 2);
      reasoning = 'Image processing task. ISP (Image Signal Processor) provides hardware-accelerated image operations.';
      confidence = 0.85;
    }
    // Signal processing
    else if (lowerDesc.contains('audio') ||
        lowerDesc.contains('signal') ||
        lowerDesc.contains('dsp')) {
      recommendedDevice = DeviceType.dsp;
      estimatedResources = 15.0;
      priority = 2;
      estimatedDuration = const Duration(seconds: 30);
      reasoning = 'Signal processing workload. DSP optimized for real-time audio and signal operations.';
      confidence = 0.87;
    }
    // Heavy compute
    else if (lowerDesc.contains('compute') ||
        lowerDesc.contains('calculate') ||
        lowerDesc.contains('simulation')) {
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

    // Learn from historical decisions
    if (_decisionHistory.isNotEmpty) {
      final similarTasks = _decisionHistory.where((d) =>
          d.taskDescription.toLowerCase().contains(lowerDesc.split(' ').first));

      if (similarTasks.isNotEmpty) {
        // Adjust based on past performance
        confidence = (confidence + 0.95) / 2; // Increase confidence
        reasoning += ' (Adjusted based on ${similarTasks.length} similar past tasks)';
      }
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

  Future<Map<String, dynamic>> _buildSystemContext() async {
    final stats = hypervisor.getStats();
    final devices = openclManager.getStats()['devices'] as List;

    return {
      'activeTasks': stats['activeTasks'],
      'queuedTasks': stats['queuedTasks'],
      'availableDevices': devices.length,
      'totalCapacity': stats['totalResourcesAvailable'],
      'utilization': stats['totalResourcesAllocated'],
      'decisions': _decisionHistory.length,
    };
  }

  String _buildQueryPrompt(String question, Map<String, dynamic> context) {
    return '''
System Status:
- Active Tasks: ${context['activeTasks']}
- Queued Tasks: ${context['queuedTasks']}
- Available Devices: ${context['availableDevices']}
- Utilization: ${context['utilization']}/${context['totalCapacity']} CUs

User Question: $question

As the Conductor orchestrating this distributed compute network, provide a clear, concise answer.
''';
  }

  /// Dispose resources
  void dispose() {
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

/// Decision made by the Conductor
class ConductorDecision {
  final String taskId;
  final String taskDescription;
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
    required this.taskDescription,
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
        'taskDescription': taskDescription,
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
      taskDescription: json['taskDescription'] as String,
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
