import '../blockchain/blockchain.dart';
import '../compute/opencl_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// AI Model Marketplace - Users can choose between competing AI models
/// Models compete on price, performance, and specialization
class AIModelMarketplace {
  final Blockchain blockchain;
  final OpenCLManager openclManager;
  final Logger _logger = Logger();

  final Map<String, AIModel> _models = {};
  String? _activeModelId;

  AIModelMarketplace({
    required this.blockchain,
    required this.openclManager,
  }) {
    _initializeDefaultModels();
  }

  /// Initialize default AI models
  void _initializeDefaultModels() {
    // Add default models
    registerModel(AIModel(
      id: 'llama-3-8b',
      name: 'Llama 3 8B',
      provider: 'Meta',
      modelType: AIModelType.language,
      size: ModelSize.small,
      pricePerToken: 0.0001,
      specialization: ['general', 'chat', 'reasoning'],
      requiresDevice: DeviceType.gpu,
      isLocal: true,
      metadata: {
        'parameters': '8B',
        'context': 8192,
        'license': 'open-source',
      },
    ));

    registerModel(AIModel(
      id: 'claude-sonnet',
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      modelType: AIModelType.language,
      size: ModelSize.large,
      pricePerToken: 0.003,
      specialization: ['coding', 'analysis', 'reasoning'],
      requiresDevice: null, // Cloud-based
      isLocal: false,
      metadata: {
        'context': 200000,
        'capabilities': ['vision', 'tool-use'],
      },
    ));

    registerModel(AIModel(
      id: 'gpt-4-turbo',
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      modelType: AIModelType.language,
      size: ModelSize.large,
      pricePerToken: 0.01,
      specialization: ['general', 'creative', 'analysis'],
      requiresDevice: null,
      isLocal: false,
      metadata: {
        'context': 128000,
        'capabilities': ['vision', 'json-mode'],
      },
    ));

    registerModel(AIModel(
      id: 'mistral-7b',
      name: 'Mistral 7B',
      provider: 'Mistral AI',
      modelType: AIModelType.language,
      size: ModelSize.small,
      pricePerToken: 0.00005,
      specialization: ['efficiency', 'code'],
      requiresDevice: DeviceType.gpu,
      isLocal: true,
      metadata: {
        'parameters': '7B',
        'license': 'apache-2.0',
      },
    ));

    registerModel(AIModel(
      id: 'stable-diffusion-xl',
      name: 'Stable Diffusion XL',
      provider: 'Stability AI',
      modelType: AIModelType.image,
      size: ModelSize.medium,
      pricePerToken: 0.002,
      specialization: ['image-generation', 'art'],
      requiresDevice: DeviceType.gpu,
      isLocal: true,
      metadata: {
        'resolution': '1024x1024',
        'license': 'open-source',
      },
    ));

    registerModel(AIModel(
      id: 'whisper-large',
      name: 'Whisper Large',
      provider: 'OpenAI',
      modelType: AIModelType.audio,
      size: ModelSize.medium,
      pricePerToken: 0.0001,
      specialization: ['transcription', 'translation'],
      requiresDevice: DeviceType.gpu,
      isLocal: true,
      metadata: {
        'languages': 99,
        'license': 'mit',
      },
    ));

    _logger.i('Initialized ${_models.length} AI models');
  }

  /// Register a new AI model
  void registerModel(AIModel model) {
    _models[model.id] = model;

    blockchain.addBlock({
      'type': 'ai_model_registration',
      'modelId': model.id,
      'name': model.name,
      'provider': model.provider,
      'modelType': model.modelType.name,
      'pricePerToken': model.pricePerToken,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Registered AI model: ${model.name}');
  }

  /// Select active AI model for user
  Future<void> selectModel(String modelId, String userId) async {
    final model = _models[modelId];

    if (model == null) {
      throw ModelException('Model not found: $modelId');
    }

    // Check if device supports the model
    if (model.requiresDevice != null && model.isLocal) {
      final hasDevice = await _checkDeviceAvailability(model.requiresDevice!);
      if (!hasDevice) {
        throw ModelException(
          'Required device ${model.requiresDevice!.name} not available. '
          'Model requires local ${model.requiresDevice!.name} execution.',
        );
      }
    }

    _activeModelId = modelId;

    blockchain.addBlock({
      'type': 'ai_model_selection',
      'userId': userId,
      'modelId': modelId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('User $userId selected model: ${model.name}');
  }

  /// Get model recommendations based on task
  List<AIModel> getRecommendations({
    required AIModelType taskType,
    double? maxPrice,
    bool? localOnly,
    List<String>? requiredCapabilities,
  }) {
    var candidates = _models.values.where((m) => m.modelType == taskType);

    if (maxPrice != null) {
      candidates = candidates.where((m) => m.pricePerToken <= maxPrice);
    }

    if (localOnly == true) {
      candidates = candidates.where((m) => m.isLocal);
    }

    if (requiredCapabilities != null) {
      candidates = candidates.where((m) =>
        requiredCapabilities.every((cap) => m.specialization.contains(cap)));
    }

    final sorted = candidates.toList()
      ..sort((a, b) {
        // Sort by price (cheaper first)
        final priceDiff = a.pricePerToken.compareTo(b.pricePerToken);
        if (priceDiff != 0) return priceDiff;

        // Then by size (smaller first for efficiency)
        return a.size.index.compareTo(b.size.index);
      });

    return sorted;
  }

  /// Run inference with selected model
  Future<AIInferenceResult> runInference({
    required String userId,
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    final modelId = _activeModelId;
    if (modelId == null) {
      throw ModelException('No model selected');
    }

    final model = _models[modelId]!;

    final startTime = DateTime.now();

    // Execute inference
    final result = await _executeInference(model, prompt, parameters);

    final duration = DateTime.now().difference(startTime);
    final tokenCount = _estimateTokens(prompt + result);
    final cost = tokenCount * model.pricePerToken;

    // Record usage
    blockchain.addBlock({
      'type': 'ai_inference',
      'userId': userId,
      'modelId': modelId,
      'tokenCount': tokenCount,
      'cost': cost,
      'duration': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return AIInferenceResult(
      modelId: modelId,
      modelName: model.name,
      output: result,
      tokenCount: tokenCount,
      cost: cost,
      duration: duration,
    );
  }

  /// Compare models side-by-side
  Future<Map<String, AIInferenceResult>> compareModels({
    required String userId,
    required List<String> modelIds,
    required String prompt,
  }) async {
    final results = <String, AIInferenceResult>{};

    for (final modelId in modelIds) {
      await selectModel(modelId, userId);
      final result = await runInference(userId: userId, prompt: prompt);
      results[modelId] = result;
    }

    return results;
  }

  /// Get marketplace statistics
  Map<String, dynamic> getMarketplaceStats() {
    final byType = <AIModelType, int>{};
    final byProvider = <String, int>{};

    for (final model in _models.values) {
      byType[model.modelType] = (byType[model.modelType] ?? 0) + 1;
      byProvider[model.provider] = (byProvider[model.provider] ?? 0) + 1;
    }

    return {
      'totalModels': _models.length,
      'byType': byType.map((k, v) => MapEntry(k.name, v)),
      'byProvider': byProvider,
      'activeModel': _activeModelId,
    };
  }

  Future<bool> _checkDeviceAvailability(DeviceType deviceType) async {
    final devices = openclManager.getDevices();
    return devices.any((d) => d.type == deviceType && d.isAvailable);
  }

  Future<String> _executeInference(
    AIModel model,
    String prompt,
    Map<String, dynamic>? parameters,
  ) async {
    // In production, this would call the actual model
    // For local models, run on OpenCL
    // For cloud models, call API

    if (model.isLocal) {
      // Execute on local device
      _logger.d('Running ${model.name} locally...');
      await Future.delayed(const Duration(seconds: 1));
      return 'Local inference result from ${model.name}';
    } else {
      // Call cloud API
      _logger.d('Calling ${model.name} API...');
      await Future.delayed(const Duration(seconds: 2));
      return 'Cloud inference result from ${model.name}';
    }
  }

  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  AIModel? get activeModel => _activeModelId != null ? _models[_activeModelId] : null;
  List<AIModel> get allModels => _models.values.toList();
}

/// AI Model definition
class AIModel {
  final String id;
  final String name;
  final String provider;
  final AIModelType modelType;
  final ModelSize size;
  final double pricePerToken;
  final List<String> specialization;
  final DeviceType? requiresDevice;
  final bool isLocal;
  final Map<String, dynamic> metadata;

  AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.modelType,
    required this.size,
    required this.pricePerToken,
    required this.specialization,
    required this.requiresDevice,
    required this.isLocal,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider,
    'modelType': modelType.name,
    'size': size.name,
    'pricePerToken': pricePerToken,
    'specialization': specialization,
    'requiresDevice': requiresDevice?.name,
    'isLocal': isLocal,
    'metadata': metadata,
  };
}

enum AIModelType {
  language,
  image,
  audio,
  video,
  multimodal,
}

enum ModelSize {
  tiny,    // < 1B parameters
  small,   // 1-10B
  medium,  // 10-50B
  large,   // 50B+
}

/// AI inference result
class AIInferenceResult {
  final String modelId;
  final String modelName;
  final String output;
  final int tokenCount;
  final double cost;
  final Duration duration;

  AIInferenceResult({
    required this.modelId,
    required this.modelName,
    required this.output,
    required this.tokenCount,
    required this.cost,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'modelName': modelName,
    'output': output,
    'tokenCount': tokenCount,
    'cost': cost,
    'durationMs': duration.inMilliseconds,
  };
}

class ModelException implements Exception {
  final String message;
  ModelException(this.message);

  @override
  String toString() => 'ModelException: $message';
}
