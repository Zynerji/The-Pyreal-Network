import 'dart:async';
import 'dart:math';
import '../blockchain/blockchain.dart';
import '../compute/device_type.dart';
import '../orchestration/conductor.dart';
import '../storage/hdp_storage.dart';
import 'package:logger/logger.dart';

/// Model categories for collaborative training
enum ModelCategory {
  imageClassification,
  textGeneration,
  speechRecognition,
  financialPrediction,
  codeGeneration,
  objectDetection,
  sentimentAnalysis,
  translationModel,
}

/// Training request status
enum TrainingStatus {
  pending,
  recruiting,
  training,
  aggregating,
  validating,
  completed,
  failed,
}

/// Training quality metrics
class TrainingMetrics {
  final double accuracy;
  final double loss;
  final int epochs;
  final DateTime timestamp;
  final String nodeId;

  const TrainingMetrics({
    required this.accuracy,
    required this.loss,
    required this.epochs,
    required this.timestamp,
    required this.nodeId,
  });

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'loss': loss,
        'epochs': epochs,
        'timestamp': timestamp.toIso8601String(),
        'nodeId': nodeId,
      };
}

/// Collaborative training request
class TrainingRequest {
  final String requestId;
  final String modelName;
  final ModelCategory category;
  final String datasetDescription;
  final int targetGPUHours;
  final double rewardPoolPyreal;
  final String initiatorId;
  final DateTime createdAt;
  final DateTime? deadline;
  final Map<String, dynamic> hyperparameters;
  final int minNodes;
  final int maxNodes;

  TrainingStatus status;
  List<String> participatingNodes;
  Map<String, TrainingMetrics> nodeMetrics;
  String? finalModelHDPHash;
  double? finalAccuracy;

  TrainingRequest({
    required this.requestId,
    required this.modelName,
    required this.category,
    required this.datasetDescription,
    required this.targetGPUHours,
    required this.rewardPoolPyreal,
    required this.initiatorId,
    required this.createdAt,
    this.deadline,
    required this.hyperparameters,
    this.minNodes = 5,
    this.maxNodes = 100,
    this.status = TrainingStatus.pending,
    List<String>? participatingNodes,
    Map<String, TrainingMetrics>? nodeMetrics,
  })  : participatingNodes = participatingNodes ?? [],
        nodeMetrics = nodeMetrics ?? {};

  double get rewardPerGPUHour => rewardPoolPyreal / targetGPUHours;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'modelName': modelName,
        'category': category.name,
        'datasetDescription': datasetDescription,
        'targetGPUHours': targetGPUHours,
        'rewardPoolPyreal': rewardPoolPyreal,
        'initiatorId': initiatorId,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'hyperparameters': hyperparameters,
        'minNodes': minNodes,
        'maxNodes': maxNodes,
        'status': status.name,
        'participatingNodes': participatingNodes,
        'nodeMetrics': nodeMetrics.map((k, v) => MapEntry(k, v.toJson())),
        'finalModelHDPHash': finalModelHDPHash,
        'finalAccuracy': finalAccuracy,
      };
}

/// Model license and usage terms
enum ModelLicense {
  openSource,
  commercialAllowed,
  restrictedCommercial,
  privateUse,
}

/// Trained model available for sale/licensing
class TrainedModel {
  final String modelId;
  final String name;
  final ModelCategory category;
  final double accuracy;
  final String hdpHash;
  final ModelLicense license;
  final double pricePyreal;
  final List<String> trainers;
  final DateTime completedAt;
  final int totalDownloads;
  final double totalRevenue;
  final Map<String, dynamic> metadata;

  const TrainedModel({
    required this.modelId,
    required this.name,
    required this.category,
    required this.accuracy,
    required this.hdpHash,
    required this.license,
    required this.pricePyreal,
    required this.trainers,
    required this.completedAt,
    this.totalDownloads = 0,
    this.totalRevenue = 0.0,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'name': name,
        'category': category.name,
        'accuracy': accuracy,
        'hdpHash': hdpHash,
        'license': license.name,
        'pricePyreal': pricePyreal,
        'trainers': trainers,
        'completedAt': completedAt.toIso8601String(),
        'totalDownloads': totalDownloads,
        'totalRevenue': totalRevenue,
        'metadata': metadata,
      };
}

/// Collaborative AI model training marketplace
class CollaborativeTraining {
  final Blockchain blockchain;
  final Conductor conductor;
  final HDPStorage hdpStorage;
  final Logger _logger = Logger();

  final Map<String, TrainingRequest> _activeTrainings = {};
  final Map<String, TrainedModel> _modelMarketplace = {};
  final Map<String, List<String>> _userTrainingHistory = {};

  CollaborativeTraining({
    required this.blockchain,
    required this.conductor,
    required this.hdpStorage,
  });

  /// Create a new collaborative training request
  Future<TrainingRequest> createTrainingRequest({
    required String modelName,
    required ModelCategory category,
    required String datasetDescription,
    required int targetGPUHours,
    required double rewardPoolPyreal,
    required String initiatorId,
    DateTime? deadline,
    Map<String, dynamic>? hyperparameters,
    int minNodes = 5,
    int maxNodes = 100,
  }) async {
    final requestId = _generateRequestId();

    _logger.i('Creating collaborative training request: $modelName');

    // Verify initiator has sufficient PYREAL balance
    final balance = await blockchain.getBalance(initiatorId);
    if (balance < rewardPoolPyreal) {
      throw Exception('Insufficient balance: $balance ₱ < $rewardPoolPyreal ₱');
    }

    // Lock reward pool in smart contract
    await blockchain.createSmartContract(
      type: 'training_reward_pool',
      participants: [initiatorId],
      terms: {
        'requestId': requestId,
        'rewardPool': rewardPoolPyreal,
        'targetGPUHours': targetGPUHours,
      },
      collateral: rewardPoolPyreal,
      userId: initiatorId,
    );

    final request = TrainingRequest(
      requestId: requestId,
      modelName: modelName,
      category: category,
      datasetDescription: datasetDescription,
      targetGPUHours: targetGPUHours,
      rewardPoolPyreal: rewardPoolPyreal,
      initiatorId: initiatorId,
      createdAt: DateTime.now(),
      deadline: deadline,
      hyperparameters: hyperparameters ?? _getDefaultHyperparameters(category),
      minNodes: minNodes,
      maxNodes: maxNodes,
      status: TrainingStatus.recruiting,
    );

    _activeTrainings[requestId] = request;

    // Broadcast to network via Conductor
    await _broadcastTrainingOpportunity(request);

    _logger.i('Training request created: $requestId with ${request.rewardPerGPUHour} ₱/GPU-hour');

    return request;
  }

  /// Node volunteers to participate in training
  Future<bool> joinTraining({
    required String requestId,
    required String nodeId,
    required DeviceType deviceType,
  }) async {
    final request = _activeTrainings[requestId];
    if (request == null) {
      throw Exception('Training request not found: $requestId');
    }

    if (request.status != TrainingStatus.recruiting) {
      _logger.w('Training not recruiting: ${request.status}');
      return false;
    }

    if (request.participatingNodes.length >= request.maxNodes) {
      _logger.w('Training full: ${request.participatingNodes.length}/${request.maxNodes}');
      return false;
    }

    // Verify device has GPU capability
    if (deviceType == DeviceType.mobile || deviceType == DeviceType.iot) {
      _logger.w('Device type $deviceType not suitable for GPU training');
      return false;
    }

    // Check if node already participating
    if (request.participatingNodes.contains(nodeId)) {
      return true;
    }

    request.participatingNodes.add(nodeId);
    _userTrainingHistory.putIfAbsent(nodeId, () => []).add(requestId);

    _logger.i('Node $nodeId joined training $requestId (${request.participatingNodes.length}/${request.minNodes})');

    // Start training if minimum nodes reached
    if (request.participatingNodes.length >= request.minNodes &&
        request.status == TrainingStatus.recruiting) {
      await _startTraining(request);
    }

    return true;
  }

  /// Begin the federated training process
  Future<void> _startTraining(TrainingRequest request) async {
    request.status = TrainingStatus.training;
    _logger.i('Starting federated training: ${request.requestId} with ${request.participatingNodes.length} nodes');

    // Distribute training data fragments via HDP
    final datasetFragments = await _distributeDataset(request);

    // Simulate federated learning rounds
    final trainingDuration = Duration(
      hours: (request.targetGPUHours / request.participatingNodes.length).ceil(),
    );

    _logger.i('Training will take approximately ${trainingDuration.inHours} hours');

    // In production, this would coordinate actual training
    // For now, simulate training completion
    Timer(const Duration(seconds: 5), () async {
      await _completeTraining(request);
    });
  }

  /// Complete training and aggregate model
  Future<void> _completeTraining(TrainingRequest request) async {
    request.status = TrainingStatus.aggregating;
    _logger.i('Aggregating model from ${request.participatingNodes.length} nodes');

    // Simulate collecting gradients from all nodes
    for (final nodeId in request.participatingNodes) {
      final metrics = TrainingMetrics(
        accuracy: 0.85 + Random().nextDouble() * 0.12, // 85-97% accuracy
        loss: 0.05 + Random().nextDouble() * 0.15, // 0.05-0.2 loss
        epochs: 10,
        timestamp: DateTime.now(),
        nodeId: nodeId,
      );
      request.nodeMetrics[nodeId] = metrics;
    }

    // Calculate final model accuracy (weighted average)
    final avgAccuracy = request.nodeMetrics.values
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / request.nodeMetrics.length;

    request.finalAccuracy = avgAccuracy;

    // Store final model in HDP
    final modelData = {
      'modelId': request.requestId,
      'weights': 'simulated_model_weights',
      'architecture': request.hyperparameters,
      'accuracy': avgAccuracy,
    };

    final hdpHash = await hdpStorage.storeData(
      data: modelData.toString().codeUnits,
      userId: request.initiatorId,
    );

    request.finalModelHDPHash = hdpHash;
    request.status = TrainingStatus.completed;

    _logger.i('Training completed! Final accuracy: ${(avgAccuracy * 100).toStringAsFixed(2)}%');

    // Distribute rewards
    await _distributeTrainingRewards(request);

    // Add to marketplace
    await _addToMarketplace(request);
  }

  /// Distribute rewards to all participating nodes
  Future<void> _distributeTrainingRewards(TrainingRequest request) async {
    _logger.i('Distributing ${request.rewardPoolPyreal} ₱ to ${request.participatingNodes.length} trainers');

    final rewardPerNode = request.rewardPoolPyreal / request.participatingNodes.length;

    for (final nodeId in request.participatingNodes) {
      // Transfer PYREAL from reward pool contract to node
      await blockchain.transferPyreal(
        fromUserId: 'reward_pool_${request.requestId}',
        toUserId: nodeId,
        amount: rewardPerNode,
        memo: 'Training reward: ${request.modelName}',
      );

      _logger.i('Rewarded $nodeId: $rewardPerNode ₱');
    }

    // Give bonus to initiator (10% of reward pool returned)
    final initiatorBonus = request.rewardPoolPyreal * 0.10;
    await blockchain.transferPyreal(
      fromUserId: 'reward_pool_${request.requestId}',
      toUserId: request.initiatorId,
      amount: initiatorBonus,
      memo: 'Initiator bonus: ${request.modelName}',
    );
  }

  /// Add completed model to marketplace
  Future<void> _addToMarketplace(TrainingRequest request) async {
    if (request.finalModelHDPHash == null || request.finalAccuracy == null) {
      return;
    }

    // Calculate market price based on accuracy and category
    final basePrice = _getBasePriceForCategory(request.category);
    final qualityMultiplier = request.finalAccuracy! * 1.5; // 85% accuracy = 1.275x
    final marketPrice = basePrice * qualityMultiplier;

    final model = TrainedModel(
      modelId: request.requestId,
      name: request.modelName,
      category: request.category,
      accuracy: request.finalAccuracy!,
      hdpHash: request.finalModelHDPHash!,
      license: ModelLicense.commercialAllowed,
      pricePyreal: marketPrice,
      trainers: request.participatingNodes,
      completedAt: DateTime.now(),
      metadata: {
        'description': request.datasetDescription,
        'hyperparameters': request.hyperparameters,
        'totalGPUHours': request.targetGPUHours,
        'trainingCost': request.rewardPoolPyreal,
      },
    );

    _modelMarketplace[model.modelId] = model;

    _logger.i('Model added to marketplace: ${model.name} at ${model.pricePyreal} ₱');
  }

  /// Purchase a trained model from marketplace
  Future<String> purchaseModel({
    required String modelId,
    required String buyerId,
  }) async {
    final model = _modelMarketplace[modelId];
    if (model == null) {
      throw Exception('Model not found: $modelId');
    }

    // Check buyer balance
    final balance = await blockchain.getBalance(buyerId);
    if (balance < model.pricePyreal) {
      throw Exception('Insufficient balance: $balance ₱ < ${model.pricePyreal} ₱');
    }

    // Process payment with revenue split
    await _processModelSale(model, buyerId);

    // Grant access to model HDP
    await hdpStorage.grantAccess(
      dataHash: model.hdpHash,
      userId: buyerId,
    );

    _logger.i('Model purchased: ${model.name} by $buyerId');

    return model.hdpHash;
  }

  /// Process model sale revenue distribution
  Future<void> _processModelSale(TrainedModel model, String buyerId) async {
    final price = model.pricePyreal;

    // Revenue split: 60% trainers, 30% treasury, 10% initiator
    final trainersShare = price * 0.60;
    final treasuryShare = price * 0.30;
    final initiatorShare = price * 0.10;

    // Split trainer share equally
    final perTrainerAmount = trainersShare / model.trainers.length;

    for (final trainerId in model.trainers) {
      await blockchain.transferPyreal(
        fromUserId: buyerId,
        toUserId: trainerId,
        amount: perTrainerAmount,
        memo: 'Model sale revenue: ${model.name}',
      );
    }

    // Treasury share (burned/distributed)
    await blockchain.transferPyreal(
      fromUserId: buyerId,
      toUserId: 'treasury',
      amount: treasuryShare,
      memo: 'Model sale: treasury share',
    );

    // Initiator share (from metadata)
    final initiatorId = model.metadata['initiatorId'] ?? 'unknown';
    if (initiatorId != 'unknown') {
      await blockchain.transferPyreal(
        fromUserId: buyerId,
        toUserId: initiatorId,
        amount: initiatorShare,
        memo: 'Model sale: initiator bonus',
      );
    }
  }

  /// Get all available models in marketplace
  List<TrainedModel> getMarketplaceModels({
    ModelCategory? category,
    double? minAccuracy,
    double? maxPrice,
  }) {
    var models = _modelMarketplace.values.toList();

    if (category != null) {
      models = models.where((m) => m.category == category).toList();
    }

    if (minAccuracy != null) {
      models = models.where((m) => m.accuracy >= minAccuracy).toList();
    }

    if (maxPrice != null) {
      models = models.where((m) => m.pricePyreal <= maxPrice).toList();
    }

    // Sort by accuracy descending
    models.sort((a, b) => b.accuracy.compareTo(a.accuracy));

    return models;
  }

  /// Get user's training history and earnings
  Future<Map<String, dynamic>> getUserTrainingStats(String userId) async {
    final trainings = _userTrainingHistory[userId] ?? [];

    var totalEarnings = 0.0;
    var totalGPUHours = 0.0;
    final completedTrainings = <TrainingRequest>[];

    for (final requestId in trainings) {
      final request = _activeTrainings[requestId];
      if (request?.status == TrainingStatus.completed) {
        completedTrainings.add(request!);
        totalEarnings += request.rewardPoolPyreal / request.participatingNodes.length;
        totalGPUHours += request.targetGPUHours / request.participatingNodes.length;
      }
    }

    return {
      'totalTrainings': completedTrainings.length,
      'totalEarnings': totalEarnings,
      'totalGPUHours': totalGPUHours,
      'averageEarningPerHour': totalGPUHours > 0 ? totalEarnings / totalGPUHours : 0.0,
      'completedModels': completedTrainings.map((t) => t.modelName).toList(),
    };
  }

  // Helper methods

  Future<void> _broadcastTrainingOpportunity(TrainingRequest request) async {
    // In production, this would use Conductor to broadcast to network
    _logger.i('Broadcasting training opportunity: ${request.rewardPerGPUHour} ₱/GPU-hour');
  }

  Future<List<String>> _distributeDataset(TrainingRequest request) async {
    // In production, this would fragment dataset via HDP
    _logger.i('Distributing dataset fragments to ${request.participatingNodes.length} nodes');
    return List.generate(request.participatingNodes.length, (i) => 'fragment_$i');
  }

  Map<String, dynamic> _getDefaultHyperparameters(ModelCategory category) {
    switch (category) {
      case ModelCategory.imageClassification:
        return {'epochs': 10, 'batch_size': 32, 'learning_rate': 0.001};
      case ModelCategory.textGeneration:
        return {'epochs': 5, 'batch_size': 16, 'learning_rate': 0.0001};
      case ModelCategory.speechRecognition:
        return {'epochs': 15, 'batch_size': 64, 'learning_rate': 0.001};
      default:
        return {'epochs': 10, 'batch_size': 32, 'learning_rate': 0.001};
    }
  }

  double _getBasePriceForCategory(ModelCategory category) {
    switch (category) {
      case ModelCategory.imageClassification:
        return 500.0;
      case ModelCategory.textGeneration:
        return 1000.0;
      case ModelCategory.speechRecognition:
        return 800.0;
      case ModelCategory.financialPrediction:
        return 2000.0;
      case ModelCategory.codeGeneration:
        return 1500.0;
      default:
        return 500.0;
    }
  }

  String _generateRequestId() {
    return 'train_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
