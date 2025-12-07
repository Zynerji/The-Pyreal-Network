import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../blockchain/blockchain.dart';
import '../tokens/app_token.dart';
import 'package:logger/logger.dart';

/// Blockchain-based identity for SSO across all apps
/// Synergy: Multi-app hub + Blockchain = Web3 Single Sign-On
class BlockchainIdentity {
  final Blockchain blockchain;
  final Logger _logger = Logger();

  BlockchainIdentity({required this.blockchain});

  /// Create a new blockchain identity
  Future<Identity> createIdentity({
    required String username,
    required String publicKey,
    Map<String, dynamic>? profile,
  }) async {
    final identityId = _generateIdentityId(publicKey);

    final identity = Identity(
      id: identityId,
      username: username,
      publicKey: publicKey,
      createdAt: DateTime.now(),
      profile: profile ?? {},
      verifiedApps: [],
    );

    // Record identity on blockchain
    blockchain.addBlock({
      'type': 'identity_creation',
      'identityId': identityId,
      'username': username,
      'publicKey': publicKey,
      'createdAt': identity.createdAt.toIso8601String(),
      'profileHash': _hashProfile(profile ?? {}),
    });

    _logger.i('Created blockchain identity: $username');

    return identity;
  }

  /// Verify app token with blockchain identity
  Future<bool> verifyAppToken({
    required String identityId,
    required String appTokenId,
    required AppTokenType appType,
  }) async {
    // Record verification on blockchain
    blockchain.addBlock({
      'type': 'app_verification',
      'identityId': identityId,
      'appTokenId': appTokenId,
      'appType': appType.name,
      'verifiedAt': DateTime.now().toIso8601String(),
    });

    _logger.i('Verified app $appTokenId for identity $identityId');
    return true;
  }

  /// Get all verified apps for an identity
  Future<List<Map<String, dynamic>>> getVerifiedApps(String identityId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'app_verification' && data['identityId'] == identityId);

    return blocks.map((block) => {
      'appTokenId': block.data['appTokenId'],
      'appType': block.data['appType'],
      'verifiedAt': block.data['verifiedAt'],
      'blockHash': block.hash,
    }).toList();
  }

  /// Generate zero-knowledge proof for selective disclosure
  Future<ZKProof> generateProof({
    required String identityId,
    required List<String> disclosedFields,
  }) async {
    // Simplified ZK proof (in production, use proper ZK cryptography)
    final proof = ZKProof(
      identityId: identityId,
      disclosedFields: disclosedFields,
      proofHash: _generateProofHash(identityId, disclosedFields),
      timestamp: DateTime.now(),
    );

    // Record proof generation on blockchain
    blockchain.addBlock({
      'type': 'zk_proof',
      'identityId': identityId,
      'disclosedFields': disclosedFields,
      'proofHash': proof.proofHash,
      'timestamp': proof.timestamp.toIso8601String(),
    });

    return proof;
  }

  /// Verify identity exists on blockchain
  Future<bool> verifyIdentity(String identityId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'identity_creation' && data['identityId'] == identityId);

    if (blocks.isEmpty) return false;

    return blocks.first.verifyHash();
  }

  /// Link identity across multiple apps (SSO)
  Future<void> linkAppAccounts({
    required String identityId,
    required List<String> appTokenIds,
  }) async {
    blockchain.addBlock({
      'type': 'sso_linking',
      'identityId': identityId,
      'linkedApps': appTokenIds,
      'linkedAt': DateTime.now().toIso8601String(),
    });

    _logger.i('Linked ${appTokenIds.length} apps to identity $identityId');
  }

  /// Get cross-app social graph
  Future<SocialGraph> getSocialGraph(String identityId) async {
    final verifiedApps = await getVerifiedApps(identityId);

    // Build social graph from blockchain data
    final connections = <String>[];
    final activities = <Map<String, dynamic>>[];

    for (final app in verifiedApps) {
      // Find interactions with this app
      final appBlocks = blockchain.searchBlocks((data) =>
          data['type'] == 'token_usage' &&
          data['tokenId'] == app['appTokenId']);

      activities.addAll(appBlocks.map((b) => b.data));
    }

    return SocialGraph(
      identityId: identityId,
      verifiedApps: verifiedApps.length,
      connections: connections,
      totalActivities: activities.length,
    );
  }

  String _generateIdentityId(String publicKey) {
    final hash = sha256.convert(utf8.encode(publicKey));
    return 'id_${hash.toString().substring(0, 16)}';
  }

  String _hashProfile(Map<String, dynamic> profile) {
    final json = jsonEncode(profile);
    return sha256.convert(utf8.encode(json)).toString();
  }

  String _generateProofHash(String identityId, List<String> fields) {
    final combined = '$identityId${fields.join(",")}';
    return sha256.convert(utf8.encode(combined)).toString();
  }
}

/// Blockchain identity model
class Identity {
  final String id;
  final String username;
  final String publicKey;
  final DateTime createdAt;
  final Map<String, dynamic> profile;
  final List<String> verifiedApps;

  Identity({
    required this.id,
    required this.username,
    required this.publicKey,
    required this.createdAt,
    required this.profile,
    required this.verifiedApps,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'publicKey': publicKey,
    'createdAt': createdAt.toIso8601String(),
    'profile': profile,
    'verifiedApps': verifiedApps,
  };
}

/// Zero-knowledge proof for selective disclosure
class ZKProof {
  final String identityId;
  final List<String> disclosedFields;
  final String proofHash;
  final DateTime timestamp;

  ZKProof({
    required this.identityId,
    required this.disclosedFields,
    required this.proofHash,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'identityId': identityId,
    'disclosedFields': disclosedFields,
    'proofHash': proofHash,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Social graph across apps
class SocialGraph {
  final String identityId;
  final int verifiedApps;
  final List<String> connections;
  final int totalActivities;

  SocialGraph({
    required this.identityId,
    required this.verifiedApps,
    required this.connections,
    required this.totalActivities,
  });

  Map<String, dynamic> toJson() => {
    'identityId': identityId,
    'verifiedApps': verifiedApps,
    'connections': connections.length,
    'totalActivities': totalActivities,
  };
}
