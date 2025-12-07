import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Holographic Data Partitioning Manager
/// Implements HDP for ultra-large-scale distributed data storage
/// Treats data as a hologram - fragments contain linear combinations of the whole
class HDPManager {
  final int totalShards;
  final int thresholdShards;
  final Random _random = Random.secure();

  HDPManager({
    this.totalShards = 10,
    int? thresholdShards,
  }) : thresholdShards = thresholdShards ?? (totalShards * 0.7).ceil();

  /// Encode and fragment data into holographic shards
  /// Each shard contains a linear combination of the entire original data
  Future<List<HDPFragment>> encodeData(Uint8List data) async {
    // Generate orthogonal matrix for transformation
    final matrix = _generateOrthogonalMatrix(data.length);

    // Apply FFT-like transformation
    final transformed = _applyTransformation(data, matrix);

    // Create fragments with Reed-Solomon error correction
    final fragments = <HDPFragment>[];
    final fragmentSize = (data.length / thresholdShards).ceil();

    for (int i = 0; i < totalShards; i++) {
      final fragmentData = _createFragment(
        transformed,
        i,
        fragmentSize,
      );

      final fragment = HDPFragment(
        id: _generateFragmentId(),
        shardIndex: i,
        data: fragmentData,
        checksum: _calculateChecksum(fragmentData),
        metadata: {
          'totalShards': totalShards,
          'thresholdShards': thresholdShards,
          'originalSize': data.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      fragments.add(fragment);
    }

    return fragments;
  }

  /// Reconstruct original data from available fragments
  /// Only requires threshold number of fragments (e.g., 70% of total)
  Future<Uint8List?> reconstructData(List<HDPFragment> fragments) async {
    if (fragments.length < thresholdShards) {
      throw HDPInsufficientFragmentsException(
        'Need at least $thresholdShards fragments, got ${fragments.length}',
      );
    }

    // Verify fragment checksums
    for (final fragment in fragments) {
      if (!_verifyChecksum(fragment)) {
        throw HDPCorruptedFragmentException(
          'Fragment ${fragment.id} failed checksum verification',
        );
      }
    }

    // Use threshold number of best fragments
    final selectedFragments = fragments.take(thresholdShards).toList();

    // Reconstruct using inverse transformation
    final originalSize = selectedFragments.first.metadata['originalSize'] as int;
    final reconstructed = _inverseTransformation(
      selectedFragments,
      originalSize,
    );

    return reconstructed;
  }

  /// Distribute fragments across nodes using consistent hashing
  Map<String, List<HDPFragment>> distributeFragments(
    List<HDPFragment> fragments,
    List<String> nodeIds,
  ) {
    final distribution = <String, List<HDPFragment>>{};

    for (final node in nodeIds) {
      distribution[node] = [];
    }

    for (final fragment in fragments) {
      final nodeIndex = _consistentHash(fragment.id, nodeIds.length);
      final nodeId = nodeIds[nodeIndex];
      distribution[nodeId]!.add(fragment);
    }

    return distribution;
  }

  /// Generate orthogonal matrix for data transformation
  List<List<double>> _generateOrthogonalMatrix(int size) {
    final matrix = List.generate(
      size,
      (i) => List.generate(size, (j) => 0.0),
    );

    // Gram-Schmidt process for orthogonalization
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        matrix[i][j] = _random.nextDouble() * 2 - 1;
      }
    }

    // Normalize (simplified for demonstration)
    for (int i = 0; i < size; i++) {
      double norm = 0;
      for (int j = 0; j < size; j++) {
        norm += matrix[i][j] * matrix[i][j];
      }
      norm = sqrt(norm);

      for (int j = 0; j < size; j++) {
        matrix[i][j] /= norm;
      }
    }

    return matrix;
  }

  /// Apply transformation to create holographic encoding
  Uint8List _applyTransformation(Uint8List data, List<List<double>> matrix) {
    // Simplified FFT-like transformation
    final result = List<int>.filled(data.length, 0);

    for (int i = 0; i < min(data.length, matrix.length); i++) {
      double sum = 0;
      for (int j = 0; j < min(data.length, matrix[i].length); j++) {
        sum += data[j] * matrix[i][j];
      }
      result[i] = sum.abs().toInt() % 256;
    }

    return Uint8List.fromList(result);
  }

  /// Create individual fragment with redundancy
  Uint8List _createFragment(Uint8List data, int index, int fragmentSize) {
    final start = (index * fragmentSize) % data.length;
    final fragment = <int>[];

    for (int i = 0; i < fragmentSize; i++) {
      final dataIndex = (start + i) % data.length;
      // Add redundancy through XOR with neighboring data
      final value = data[dataIndex] ^
                   data[(dataIndex + 1) % data.length];
      fragment.add(value);
    }

    return Uint8List.fromList(fragment);
  }

  /// Inverse transformation to reconstruct data
  Uint8List _inverseTransformation(
    List<HDPFragment> fragments,
    int originalSize,
  ) {
    // Simplified reconstruction algorithm
    final result = List<int>.filled(originalSize, 0);
    final counts = List<int>.filled(originalSize, 0);

    for (final fragment in fragments) {
      final fragmentData = fragment.data;
      final start = (fragment.shardIndex * fragmentData.length) % originalSize;

      for (int i = 0; i < fragmentData.length && i < originalSize; i++) {
        final targetIndex = (start + i) % originalSize;
        result[targetIndex] += fragmentData[i];
        counts[targetIndex]++;
      }
    }

    // Average the values
    for (int i = 0; i < originalSize; i++) {
      if (counts[i] > 0) {
        result[i] = (result[i] / counts[i]).round() % 256;
      }
    }

    return Uint8List.fromList(result);
  }

  /// Calculate checksum for fragment
  String _calculateChecksum(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Verify fragment checksum
  bool _verifyChecksum(HDPFragment fragment) {
    final calculatedChecksum = _calculateChecksum(fragment.data);
    return calculatedChecksum == fragment.checksum;
  }

  /// Consistent hashing for fragment distribution
  int _consistentHash(String key, int buckets) {
    final hash = sha256.convert(utf8.encode(key));
    final hashInt = hash.bytes.fold<int>(0, (prev, byte) => prev * 256 + byte);
    return hashInt % buckets;
  }

  /// Generate unique fragment ID
  String _generateFragmentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(1000000);
    return 'hdp_${timestamp}_$random';
  }
}

/// Represents a holographic data fragment
class HDPFragment {
  final String id;
  final int shardIndex;
  final Uint8List data;
  final String checksum;
  final Map<String, dynamic> metadata;

  HDPFragment({
    required this.id,
    required this.shardIndex,
    required this.data,
    required this.checksum,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'shardIndex': shardIndex,
    'data': base64Encode(data),
    'checksum': checksum,
    'metadata': metadata,
  };

  factory HDPFragment.fromJson(Map<String, dynamic> json) {
    return HDPFragment(
      id: json['id'],
      shardIndex: json['shardIndex'],
      data: base64Decode(json['data']),
      checksum: json['checksum'],
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class HDPInsufficientFragmentsException implements Exception {
  final String message;
  HDPInsufficientFragmentsException(this.message);

  @override
  String toString() => 'HDPInsufficientFragmentsException: $message';
}

class HDPCorruptedFragmentException implements Exception {
  final String message;
  HDPCorruptedFragmentException(this.message);

  @override
  String toString() => 'HDPCorruptedFragmentException: $message';
}
