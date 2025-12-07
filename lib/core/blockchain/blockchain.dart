import 'dart:convert';
import 'package:logger/logger.dart';
import 'block.dart';

/// Pyreal private blockchain implementation
/// Stores token minting transactions and app state
class Blockchain {
  final List<Block> _chain = [];
  final int difficulty;
  final Logger _logger = Logger();

  Blockchain({this.difficulty = 4}) {
    _chain.add(Block.genesis());
  }

  /// Get the entire blockchain
  List<Block> get chain => List.unmodifiable(_chain);

  /// Get the latest block
  Block get latestBlock => _chain.last;

  /// Get blockchain length
  int get length => _chain.length;

  /// Add a new block to the chain
  bool addBlock(Map<String, dynamic> data) {
    try {
      final newBlock = Block.mine(
        index: _chain.length,
        data: data,
        previousHash: latestBlock.hash,
        difficulty: difficulty,
      );

      if (_isValidNewBlock(newBlock, latestBlock)) {
        _chain.add(newBlock);
        _logger.i('Block ${newBlock.index} added to chain');
        return true;
      }

      _logger.w('Invalid block rejected');
      return false;
    } catch (e) {
      _logger.e('Error adding block: $e');
      return false;
    }
  }

  /// Validate a new block
  bool _isValidNewBlock(Block newBlock, Block previousBlock) {
    if (previousBlock.index + 1 != newBlock.index) {
      _logger.w('Invalid index');
      return false;
    }

    if (previousBlock.hash != newBlock.previousHash) {
      _logger.w('Invalid previous hash');
      return false;
    }

    if (!newBlock.verifyHash()) {
      _logger.w('Invalid hash');
      return false;
    }

    if (!newBlock.hash.startsWith('0' * difficulty)) {
      _logger.w('Insufficient proof of work');
      return false;
    }

    return true;
  }

  /// Validate the entire blockchain
  bool isValid() {
    for (int i = 1; i < _chain.length; i++) {
      final currentBlock = _chain[i];
      final previousBlock = _chain[i - 1];

      if (!_isValidNewBlock(currentBlock, previousBlock)) {
        return false;
      }
    }
    return true;
  }

  /// Get block by index
  Block? getBlock(int index) {
    if (index >= 0 && index < _chain.length) {
      return _chain[index];
    }
    return null;
  }

  /// Search blocks by data criteria
  List<Block> searchBlocks(bool Function(Map<String, dynamic>) predicate) {
    return _chain.where((block) => predicate(block.data)).toList();
  }

  /// Get blocks by transaction type
  List<Block> getBlocksByType(String type) {
    return searchBlocks((data) => data['type'] == type);
  }

  /// Add token minting transaction
  bool mintToken(Map<String, dynamic> tokenData) {
    return addBlock({
      'type': 'token_mint',
      'timestamp': DateTime.now().toIso8601String(),
      'data': tokenData,
    });
  }

  /// Add token usage transaction
  bool useToken(String tokenId, Map<String, dynamic> usageData) {
    return addBlock({
      'type': 'token_usage',
      'timestamp': DateTime.now().toIso8601String(),
      'tokenId': tokenId,
      'data': usageData,
    });
  }

  /// Export blockchain to JSON
  String toJson() {
    return jsonEncode({
      'chain': _chain.map((block) => block.toJson()).toList(),
      'difficulty': difficulty,
    });
  }

  /// Import blockchain from JSON
  static Blockchain? fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      final blockchain = Blockchain(difficulty: json['difficulty']);

      blockchain._chain.clear();

      for (final blockJson in json['chain']) {
        blockchain._chain.add(Block.fromJson(blockJson));
      }

      if (blockchain.isValid()) {
        return blockchain;
      }

      return null;
    } catch (e) {
      Logger().e('Error importing blockchain: $e');
      return null;
    }
  }

  /// Get blockchain statistics
  Map<String, dynamic> getStats() {
    final tokenMints = getBlocksByType('token_mint').length;
    final tokenUsages = getBlocksByType('token_usage').length;

    return {
      'totalBlocks': _chain.length,
      'tokenMints': tokenMints,
      'tokenUsages': tokenUsages,
      'difficulty': difficulty,
      'isValid': isValid(),
      'latestBlockHash': latestBlock.hash,
    };
  }
}
