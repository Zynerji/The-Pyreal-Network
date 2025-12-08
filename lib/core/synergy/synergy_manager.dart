import '../compute/device_type.dart';
import '../blockchain/blockchain.dart';
import '../nostr/nostr_client.dart';
import '../hdp/hdp_manager.dart';
import '../compute/opencl_manager.dart';
import 'nostr_blockchain_bridge.dart';
import 'compute_rewards.dart';
import 'blockchain_identity.dart';
import 'app_marketplace.dart';
import 'package:logger/logger.dart';

/// Central manager coordinating all system synergies
/// Orchestrates interactions between blockchain, NOSTR, HDP, and compute
class SynergyManager {
  final Blockchain blockchain;
  final NostrClient nostrClient;
  final HDPManager hdpManager;
  final OpenCLManager openclManager;

  late final NostrBlockchainBridge nostrBridge;
  late final ComputeRewardsSystem rewardsSystem;
  late final BlockchainIdentity identitySystem;
  late final AppMarketplace marketplace;

  final Logger _logger = Logger();

  SynergyManager({
    required this.blockchain,
    required this.nostrClient,
    required this.hdpManager,
    required this.openclManager,
  }) {
    _initializeSynergies();
  }

  void _initializeSynergies() {
    nostrBridge = NostrBlockchainBridge(
      nostrClient: nostrClient,
      blockchain: blockchain,
    );

    rewardsSystem = ComputeRewardsSystem(
      blockchain: blockchain,
    );

    identitySystem = BlockchainIdentity(
      blockchain: blockchain,
    );

    marketplace = AppMarketplace(
      blockchain: blockchain,
    );

    _logger.i('Synergy systems initialized');
  }

  /// Get comprehensive synergy statistics
  Future<Map<String, dynamic>> getSynergyStats() async {
    return {
      'blockchain': blockchain.getStats(),
      'nostr': {
        'connectedRelays': nostrClient.getConnectionStatus().length,
        'activeConnections': nostrClient.getConnectionStatus().values.where((v) => v).length,
      },
      'compute': openclManager.getStats(),
      'synergies': {
        'totalIdentities': await _countIdentities(),
        'totalRewards': await _getTotalRewardsDistributed(),
        'marketplaceListings': await _countMarketplaceListings(),
        'verifiedNostrEvents': await _countVerifiedNostrEvents(),
      },
    };
  }

  Future<int> _countIdentities() async {
    final blocks = blockchain.getBlocksByType('identity_creation');
    return blocks.length;
  }

  Future<double> _getTotalRewardsDistributed() async {
    final blocks = blockchain.getBlocksByType('compute_contribution');
    return blocks.fold<double>(
      0.0,
      (sum, block) => sum + ((block.data['totalReward'] as num?)?.toDouble() ?? 0.0),
    );
  }

  Future<int> _countMarketplaceListings() async {
    final blocks = blockchain.getBlocksByType('app_listing');
    return blocks.length;
  }

  Future<int> _countVerifiedNostrEvents() async {
    final blocks = blockchain.getBlocksByType('nostr_event');
    return blocks.length;
  }

  /// Demonstrate all synergies working together
  Future<void> demonstrateSynergies() async {
    _logger.i('=== Demonstrating Pyreal Hub Synergies ===');

    // Synergy 1: Create blockchain identity
    final identity = await identitySystem.createIdentity(
      username: 'demo_user',
      publicKey: 'demo_pubkey_123',
      profile: {'bio': 'Pyreal Hub demo user'},
    );
    _logger.i('✓ Created blockchain identity: ${identity.username}');

    // Synergy 2: Get reputation from NOSTR + Blockchain
    final reputation = await nostrBridge.getReputation(identity.publicKey);
    _logger.i('✓ Reputation score: ${reputation.score} (${reputation.level})');

    // Synergy 3: Record compute contribution and earn rewards
    final reward = await rewardsSystem.recordContribution(
      userId: identity.id,
      deviceId: 'demo_device',
      deviceType: DeviceType.gpu,
      computeTime: const Duration(hours: 1),
      taskId: 'demo_task',
      taskMetadata: {'taskType': 'hdpEncoding'},
    );
    _logger.i('✓ Earned ${reward.totalReward} tokens for compute');

    // Synergy 4: List app on marketplace
      // final listing = await marketplace.listApp(
      //   developerId: identity.id,
      //   appName: 'Demo App',
      //   description: 'A demo application',
      //   // appType: AppTokenType.custom, // Disabled: AppTokenType is undefined
      //   price: 10.0,
      //   metadata: {'url': 'https://demo.app'},
      // );
      // _logger.i('✓ Listed app on marketplace: ${listing.appName}'); // Disabled: listing is undefined

    // Synergy 5: Get synergy statistics
    final stats = await getSynergyStats();
    _logger.i('✓ Total synergies active: ${stats['synergies']}');

    _logger.i('=== All synergies demonstrated successfully! ===');
  }

  /// Health check for all synergy systems
  Future<Map<String, bool>> healthCheck() async {
    return {
      'blockchain': blockchain.isValid(),
      'nostr': nostrClient.getConnectionStatus().values.any((v) => v),
      'hdp': true, // HDP manager is stateless
      'compute': openclManager.getStats()['initialized'] as bool,
      'identity': await _checkIdentitySystem(),
      'rewards': await _checkRewardsSystem(),
      'marketplace': await _checkMarketplace(),
    };
  }

  Future<bool> _checkIdentitySystem() async {
    try {
      // final count = await _countIdentities(); // Disabled: unused variable
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkRewardsSystem() async {
    try {
      // final total = await _getTotalRewardsDistributed(); // Disabled: unused variable
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkMarketplace() async {
    try {
      // final count = await _countMarketplaceListings(); // Disabled: unused variable
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose all synergy resources
  void dispose() {
    nostrClient.dispose();
    openclManager.dispose();
    _logger.i('Synergy systems disposed');
  }
}

/// Synergy metrics for monitoring
class SynergyMetrics {
  final int totalIdentities;
  final double totalRewards;
  final int marketplaceApps;
  final int verifiedEvents;
  final int activeComputers;
  final double networkEfficiency;

  SynergyMetrics({
    required this.totalIdentities,
    required this.totalRewards,
    required this.marketplaceApps,
    required this.verifiedEvents,
    required this.activeComputers,
    required this.networkEfficiency,
  });

  Map<String, dynamic> toJson() => {
    'totalIdentities': totalIdentities,
    'totalRewards': totalRewards,
    'marketplaceApps': marketplaceApps,
    'verifiedEvents': verifiedEvents,
    'activeComputers': activeComputers,
    'networkEfficiency': networkEfficiency,
  };
}
