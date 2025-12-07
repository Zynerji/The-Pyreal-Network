import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../core/tokens/app_token.dart';
import '../../core/blockchain/blockchain.dart';
import '../../core/hdp/hdp_manager.dart';
import 'package:uuid/uuid.dart';

/// Service for minting and managing app tokens
class TokenMintingService {
  final Blockchain blockchain;
  final HDPManager hdpManager;

  TokenMintingService({
    required this.blockchain,
    required this.hdpManager,
  });

  /// Mint a new AppToken with user credentials
  /// Credentials are encrypted and fragmented using HDP
  Future<AppToken> mintToken({
    required String name,
    required AppTokenType type,
    required String url,
    required Map<String, dynamic> credentials,
    required String userId,
    String? iconPath,
  }) async {
    final tokenId = const Uuid().v4();

    // Encrypt credentials
    final encryptedCredentials = await _encryptCredentials(
      credentials,
      userId,
    );

    // Fragment credentials using HDP for secure distributed storage
    final credentialsData = Uint8List.fromList(
      utf8.encode(jsonEncode(encryptedCredentials)),
    );

    final fragments = await hdpManager.encodeData(credentialsData);

    // Store fragment IDs in token
    final fragmentIds = fragments.map((f) => f.id).toList();

    // Create token
    final token = AppToken(
      id: tokenId,
      name: name,
      type: type,
      url: url,
      credentials: encryptedCredentials,
      iconPath: iconPath ?? 'assets/images/${type.name}.png',
      mintedAt: DateTime.now(),
      userId: userId,
      hdpFragments: fragmentIds,
      metadata: {
        'fragmentCount': fragments.length,
        'threshold': hdpManager.thresholdShards,
      },
    );

    // Record minting on blockchain
    blockchain.mintToken({
      'tokenId': tokenId,
      'name': name,
      'type': type.name,
      'userId': userId,
      'mintedAt': token.mintedAt.toIso8601String(),
      'fragmentIds': fragmentIds,
    });

    return token;
  }

  /// Use a token (record usage on blockchain)
  Future<void> useToken(AppToken token, Map<String, dynamic> usageData) async {
    blockchain.useToken(token.id, {
      ...usageData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Verify token integrity
  Future<bool> verifyToken(AppToken token) async {
    // Check if token exists in blockchain
    final blocks = blockchain.getBlocksByType('token_mint');
    final tokenBlock = blocks.firstWhere(
      (block) => block.data['data']['tokenId'] == token.id,
      orElse: () => throw Exception('Token not found in blockchain'),
    );

    // Verify block hash
    return tokenBlock.verifyHash();
  }

  /// Encrypt credentials using SHA-256 based encryption
  Future<Map<String, dynamic>> _encryptCredentials(
    Map<String, dynamic> credentials,
    String userId,
  ) async {
    final credentialsJson = jsonEncode(credentials);
    final key = utf8.encode(userId);
    final data = utf8.encode(credentialsJson);

    // Simple XOR encryption with hash-based key expansion
    final keyHash = sha256.convert(key);
    final encrypted = <int>[];

    for (int i = 0; i < data.length; i++) {
      final keyByte = keyHash.bytes[i % keyHash.bytes.length];
      encrypted.add(data[i] ^ keyByte);
    }

    return {
      'encrypted': base64Encode(encrypted),
      'algorithm': 'xor-sha256',
    };
  }

  /// Decrypt credentials
  Future<Map<String, dynamic>> decryptCredentials(
    Map<String, dynamic> encryptedCredentials,
    String userId,
  ) async {
    if (encryptedCredentials['algorithm'] != 'xor-sha256') {
      throw Exception('Unsupported encryption algorithm');
    }

    final encrypted = base64Decode(encryptedCredentials['encrypted']);
    final key = utf8.encode(userId);
    final keyHash = sha256.convert(key);

    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      final keyByte = keyHash.bytes[i % keyHash.bytes.length];
      decrypted.add(encrypted[i] ^ keyByte);
    }

    final credentialsJson = utf8.decode(decrypted);
    return jsonDecode(credentialsJson);
  }

  /// Get token usage history from blockchain
  List<Map<String, dynamic>> getTokenUsageHistory(String tokenId) {
    final blocks = blockchain.getBlocksByType('token_usage');
    return blocks
        .where((block) => block.data['tokenId'] == tokenId)
        .map((block) => {
              'timestamp': block.timestamp,
              'data': block.data['data'],
            })
        .toList();
  }
}
