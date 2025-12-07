import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Represents a block in the Pyreal private blockchain
class Block {
  final int index;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String previousHash;
  final String hash;
  final int nonce;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
    required this.hash,
    required this.nonce,
  });

  /// Create a new block by mining
  factory Block.mine({
    required int index,
    required Map<String, dynamic> data,
    required String previousHash,
    int difficulty = 4,
  }) {
    final timestamp = DateTime.now();
    int nonce = 0;
    String hash;

    do {
      hash = _calculateHash(
        index: index,
        timestamp: timestamp,
        data: data,
        previousHash: previousHash,
        nonce: nonce,
      );
      nonce++;
    } while (!hash.startsWith('0' * difficulty));

    return Block(
      index: index,
      timestamp: timestamp,
      data: data,
      previousHash: previousHash,
      hash: hash,
      nonce: nonce - 1,
    );
  }

  /// Genesis block creation
  factory Block.genesis() {
    final timestamp = DateTime.now();
    final data = {
      'type': 'genesis',
      'message': 'Pyreal Network Genesis Block',
    };
    const previousHash = '0';

    final hash = _calculateHash(
      index: 0,
      timestamp: timestamp,
      data: data,
      previousHash: previousHash,
      nonce: 0,
    );

    return Block(
      index: 0,
      timestamp: timestamp,
      data: data,
      previousHash: previousHash,
      hash: hash,
      nonce: 0,
    );
  }

  /// Calculate hash for a block
  static String _calculateHash({
    required int index,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    required String previousHash,
    required int nonce,
  }) {
    final input = '$index${timestamp.toIso8601String()}${jsonEncode(data)}$previousHash$nonce';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Verify block hash
  bool verifyHash() {
    final calculatedHash = _calculateHash(
      index: index,
      timestamp: timestamp,
      data: data,
      previousHash: previousHash,
      nonce: nonce,
    );
    return calculatedHash == hash;
  }

  /// Convert block to JSON
  Map<String, dynamic> toJson() => {
    'index': index,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'previousHash': previousHash,
    'hash': hash,
    'nonce': nonce,
  };

  /// Create block from JSON
  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      index: json['index'],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
      previousHash: json['previousHash'],
      hash: json['hash'],
      nonce: json['nonce'],
    );
  }

  @override
  String toString() {
    return 'Block(index: $index, hash: $hash, previousHash: $previousHash)';
  }
}
