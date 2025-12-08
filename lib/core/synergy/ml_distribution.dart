import '../compute/device_type.dart';
import '../compute/opencl_manager.dart';
import '../compute/device_detector.dart';
import '../blockchain/blockchain.dart';
import 'package:logger/logger.dart';

/// Distributed ML task processing across NPUs
/// Synergy: AI/ML Compute + NPU devices = Federated learning
class MLDistribution {
  final OpenCLManager openclManager;
  final ExtendedDeviceDetector deviceDetector;
  final Blockchain blockchain;
  final Logger _logger = Logger();

  MLDistribution({
    required this.openclManager,
    required this.deviceDetector,
    required this.blockchain,
  });

  /// Submit ML inference task
  Future<MLResult> submitInference({
    required String modelId,
    required Map<String, dynamic> inputData,
    required String userId,
  }) async {
    // Select optimal device (prefer NPU)
    final devices = openclManager.getDevices();
    final npuDevice = devices
        .where((d) => d.type.toString().contains('npu'))
        .firstOrNull;

    final selectedDevice = npuDevice ?? devices.first;

    _logger.i('Running ML inference on ${selectedDevice.name}');

    // Submit task
    final task = await openclManager.submitTask(
      taskId: 'ml_inference_${DateTime.now().millisecondsSinceEpoch}',
      kernelSource: _getMLKernel(modelId),
      inputs: inputData,
    );

    // Record on blockchain
    blockchain.addBlock({
      'type': 'ml_inference',
      'userId': userId,
      'modelId': modelId,
      'deviceType': selectedDevice.type.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return MLResult(
      modelId: modelId,
      output: task.result ?? {},
      deviceType: selectedDevice.type,
      inferenceTime: DateTime.now().difference(task.submittedAt),
    );
  }

  /// Distribute training across multiple NPUs (Federated Learning)
  Future<MLTrainingResult> distributedTraining({
    required String modelId,
    required List<Map<String, dynamic>> trainingData,
    required int epochs,
    required String userId,
  }) async {
    _logger.i('Starting distributed training for model $modelId');

    final devices = await _getNPUDevices();

    if (devices.isEmpty) {
      throw Exception('No NPU devices available for training');
    }

    // Split data across devices
    final dataPerDevice = (trainingData.length / devices.length).ceil();
    final tasks = <Future<Map<String, dynamic>>>[];

    for (int i = 0; i < devices.length; i++) {
      final start = i * dataPerDevice;
      final end = (start + dataPerDevice).clamp(0, trainingData.length);
      final deviceData = trainingData.sublist(start, end);

      tasks.add(_trainOnDevice(
        device: devices[i],
        modelId: modelId,
        data: deviceData,
        epochs: epochs,
      ));
    }

    // Wait for all devices to complete
    final results = await Future.wait(tasks);

    // Aggregate results (simplified federated averaging)
    final aggregated = _aggregateWeights(results);

    // Record on blockchain
    blockchain.addBlock({
      'type': 'ml_training',
      'userId': userId,
      'modelId': modelId,
      'devicesUsed': devices.length,
      'dataPoints': trainingData.length,
      'epochs': epochs,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _logger.i('Distributed training complete: $modelId');

    return MLTrainingResult(
      modelId: modelId,
      devicesUsed: devices.length,
      dataPoints: trainingData.length,
      epochs: epochs,
      finalWeights: aggregated,
    );
  }

  /// Get all NPU devices
  Future<List<ComputeDevice>> _getNPUDevices() async {
    final allDevices = await deviceDetector.detectAllDevices();
    return allDevices
        .where((d) => d.type.toString().contains('npu'))
        .toList();
  }

  /// Train model on specific device
  Future<Map<String, dynamic>> _trainOnDevice({
    required ComputeDevice device,
    required String modelId,
    required List<Map<String, dynamic>> data,
    required int epochs,
  }) async {
    _logger.i('Training on ${device.name} with ${data.length} samples');

    final task = await openclManager.submitTask(
      taskId: 'ml_train_${device.id}_${DateTime.now().millisecondsSinceEpoch}',
      kernelSource: _getTrainingKernel(modelId),
      inputs: {
        'data': data,
        'epochs': epochs,
      },
    );

    return task.result ?? {};
  }

  /// Aggregate weights from multiple devices (Federated Averaging)
  Map<String, dynamic> _aggregateWeights(List<Map<String, dynamic>> results) {
    // Simplified federated averaging
    // In production, properly average neural network weights
    return {
      'aggregated': true,
      'deviceCount': results.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get ML kernel for inference
  String _getMLKernel(String modelId) {
    // Simplified kernel - in production, use TensorFlow Lite, ONNX, etc.
    return '''
    __kernel void ml_inference(
      __global const float* input,
      __global float* output,
      const int inputSize
    ) {
      int gid = get_global_id(0);
      if (gid < inputSize) {
        // Simplified inference operation
        output[gid] = input[gid] * 0.5f + 0.5f;
      }
    }
    ''';
  }

  /// Get training kernel
  String _getTrainingKernel(String modelId) {
    return '''
    __kernel void ml_train(
      __global float* weights,
      __global const float* gradients,
      const float learningRate
    ) {
      int gid = get_global_id(0);
      weights[gid] -= learningRate * gradients[gid];
    }
    ''';
  }

  /// Get ML statistics
  Future<MLStats> getStats(String userId) async {
    final inferenceBlocks = blockchain.searchBlocks((data) =>
        data['type'] == 'ml_inference' && data['userId'] == userId);

    final trainingBlocks = blockchain.searchBlocks((data) =>
        data['type'] == 'ml_training' && data['userId'] == userId);

    return MLStats(
      totalInferences: inferenceBlocks.length,
      totalTrainingSessions: trainingBlocks.length,
      modelsUsed: {
        ...inferenceBlocks.map((b) => b.data['modelId'] as String),
        ...trainingBlocks.map((b) => b.data['modelId'] as String),
      }.length,
    );
  }
}

/// ML inference result
class MLResult {
  final String modelId;
  final Map<String, dynamic> output;
  final DeviceType deviceType;
  final Duration inferenceTime;

  MLResult({
    required this.modelId,
    required this.output,
    required this.deviceType,
    required this.inferenceTime,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'output': output,
    'deviceType': deviceType.name,
    'inferenceTimeMs': inferenceTime.inMilliseconds,
  };
}

/// ML training result
class MLTrainingResult {
  final String modelId;
  final int devicesUsed;
  final int dataPoints;
  final int epochs;
  final Map<String, dynamic> finalWeights;

  MLTrainingResult({
    required this.modelId,
    required this.devicesUsed,
    required this.dataPoints,
    required this.epochs,
    required this.finalWeights,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'devicesUsed': devicesUsed,
    'dataPoints': dataPoints,
    'epochs': epochs,
    'finalWeights': finalWeights,
  };
}

/// ML statistics
class MLStats {
  final int totalInferences;
  final int totalTrainingSessions;
  final int modelsUsed;

  MLStats({
    required this.totalInferences,
    required this.totalTrainingSessions,
    required this.modelsUsed,
  });

  Map<String, dynamic> toJson() => {
    'totalInferences': totalInferences,
    'totalTrainingSessions': totalTrainingSessions,
    'modelsUsed': modelsUsed,
  };
}
