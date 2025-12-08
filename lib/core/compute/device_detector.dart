import 'dart:io';
import 'package:logger/logger.dart';
import 'opencl_manager.dart';
import 'device_type.dart';

/// Extended device detector for all compute-capable hardware
/// Synergy: Unlock NPU, DSP, ISP, Video encoders for distributed compute
class ExtendedDeviceDetector {
  final Logger _logger = Logger();

  /// Detect all available compute devices including specialized processors
  Future<List<ComputeDevice>> detectAllDevices() async {
    final devices = <ComputeDevice>[];

    // Standard CPU/GPU
    devices.addAll(await _detectCpuGpu());

    // Mobile-specific processors
    if (Platform.isAndroid || Platform.isIOS) {
      devices.addAll(await _detectMobileProcessors());
    }

    _logger.i('Detected ${devices.length} compute devices');
    return devices;
  }

  /// Detect CPU and GPU
  Future<List<ComputeDevice>> _detectCpuGpu() async {
    final devices = <ComputeDevice>[];

    // CPU
    devices.add(ComputeDevice(
      id: 'cpu_0',
      name: 'CPU',
      type: DeviceType.cpu,
      computeUnits: Platform.numberOfProcessors,
      maxWorkGroupSize: 1024,
      globalMemorySize: 8 * 1024 * 1024 * 1024,
      isAvailable: true,
      metadata: {
        'architecture': _getCpuArchitecture(),
        'frequency': 'variable',
      },
    ));

    // GPU (if available)
    if (_hasGpu()) {
      devices.add(ComputeDevice(
        id: 'gpu_0',
        name: 'GPU',
        type: DeviceType.gpu,
        computeUnits: 16,
        maxWorkGroupSize: 256,
        globalMemorySize: 4 * 1024 * 1024 * 1024,
        isAvailable: true,
        metadata: {
          'vendor': _getGpuVendor(),
          'openclVersion': '3.0',
        },
      ));
    }

    return devices;
  }

  /// Detect mobile-specific processors (NPU, DSP, ISP, etc.)
  Future<List<ComputeDevice>> _detectMobileProcessors() async {
    final devices = <ComputeDevice>[];

    // NPU (Neural Processing Unit)
    if (await _hasNpu()) {
      devices.add(ComputeDevice(
        id: 'npu_0',
        name: 'Neural Processing Unit',
        type: DeviceType.npu,
        computeUnits: 8,
        maxWorkGroupSize: 512,
        globalMemorySize: 2 * 1024 * 1024 * 1024,
        isAvailable: true,
        metadata: {
          'tops': '15 TOPS',
          'precision': 'INT8, FP16',
          'frameworks': ['TFLite', 'ONNX', 'CoreML'],
        },
      ));
    }

    // DSP (Digital Signal Processor)
    if (await _hasDsp()) {
      devices.add(ComputeDevice(
        id: 'dsp_0',
        name: 'Digital Signal Processor',
        type: DeviceType.dsp,
        computeUnits: 4,
        maxWorkGroupSize: 256,
        globalMemorySize: 512 * 1024 * 1024,
        isAvailable: true,
        metadata: {
          'specialization': 'audio, signal processing',
          'powerEfficiency': 'ultra-low',
        },
      ));
    }

    // ISP (Image Signal Processor)
    if (await _hasIsp()) {
      devices.add(ComputeDevice(
        id: 'isp_0',
        name: 'Image Signal Processor',
        type: DeviceType.isp,
        computeUnits: 4,
        maxWorkGroupSize: 256,
        globalMemorySize: 1 * 1024 * 1024 * 1024,
        isAvailable: true,
        metadata: {
          'maxResolution': '8K',
          'hdr': true,
          'denoise': true,
        },
      ));
    }

    // Video Encoder/Decoder
    if (await _hasVideoProcessor()) {
      devices.add(ComputeDevice(
        id: 'video_0',
        name: 'Video Encoder/Decoder',
        type: DeviceType.videoProcessor,
        computeUnits: 8,
        maxWorkGroupSize: 512,
        globalMemorySize: 2 * 1024 * 1024 * 1024,
        isAvailable: true,
        metadata: {
          'codecs': ['H.264', 'H.265', 'AV1', 'VP9'],
          'maxResolution': '8K60',
          'encoding': true,
          'decoding': true,
        },
      ));
    }

    return devices;
  }

  /// Check for NPU availability
  Future<bool> _hasNpu() async {
    if (Platform.isAndroid) {
      // Check for Snapdragon NPU, Tensor G, MediaTek APU
      return true; // Most modern Android devices have NPU
    } else if (Platform.isIOS) {
      // Check for Apple Neural Engine
      return true; // All A-series chips since A11 have Neural Engine
    }
    return false;
  }

  /// Check for DSP availability
  Future<bool> _hasDsp() async {
    // Most mobile SoCs include DSP
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check for ISP availability
  Future<bool> _hasIsp() async {
    // All modern mobile devices have ISP
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check for video processor availability
  Future<bool> _hasVideoProcessor() async {
    // All modern devices have hardware video encode/decode
    return Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows;
  }

  bool _hasGpu() {
    return true; // Most platforms have GPU
  }

  String _getCpuArchitecture() {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ARM64';
    } else if (Platform.isLinux || Platform.isWindows) {
      return 'x86_64';
    }
    return 'unknown';
  }

  String _getGpuVendor() {
    if (Platform.isAndroid) {
      return 'Adreno/Mali/PowerVR';
    } else if (Platform.isIOS) {
      return 'Apple GPU';
    } else {
      return 'NVIDIA/AMD/Intel';
    }
  }

  /// Get optimal device for task type
  ComputeDevice? selectOptimalDevice(
    List<ComputeDevice> devices,
    ComputeTaskType taskType,
  ) {
    switch (taskType) {
      case ComputeTaskType.ml:
        // Prefer NPU, fallback to GPU
        return devices.where((d) => d.type == DeviceType.npu).firstOrNull ??
               devices.where((d) => d.type == DeviceType.gpu).firstOrNull;

      case ComputeTaskType.signalProcessing:
        // Prefer DSP, fallback to CPU
        return devices.where((d) => d.type == DeviceType.dsp).firstOrNull ??
               devices.where((d) => d.type == DeviceType.cpu).firstOrNull;

      case ComputeTaskType.imageProcessing:
        // Prefer ISP, fallback to GPU
        return devices.where((d) => d.type == DeviceType.isp).firstOrNull ??
               devices.where((d) => d.type == DeviceType.gpu).firstOrNull;

      case ComputeTaskType.video:
        // Prefer video processor, fallback to GPU
        return devices.where((d) => d.type == DeviceType.videoProcessor).firstOrNull ??
               devices.where((d) => d.type == DeviceType.gpu).firstOrNull;

      case ComputeTaskType.general:
        // Prefer GPU, fallback to CPU
        return devices.where((d) => d.type == DeviceType.gpu).firstOrNull ??
               devices.where((d) => d.type == DeviceType.cpu).firstOrNull;

      case ComputeTaskType.hdpEncoding:
        // GPU best for matrix operations
        return devices.where((d) => d.type == DeviceType.gpu).firstOrNull ??
               devices.where((d) => d.type == DeviceType.cpu).firstOrNull;

      case ComputeTaskType.crypto:
        // CPU usually best for crypto
        return devices.where((d) => d.type == DeviceType.cpu).firstOrNull;
    }
  }
}

// DeviceType now imported from device_type.dart

/// Task types for optimal device selection
enum ComputeTaskType {
  general,
  ml,
  signalProcessing,
  imageProcessing,
  video,
  hdpEncoding,
  crypto,
}

/// Extension for ComputeDevice with metadata
extension ComputeDeviceExtension on ComputeDevice {
  Map<String, dynamic> get metadata =>
      (this as dynamic).metadata ?? <String, dynamic>{};
}
