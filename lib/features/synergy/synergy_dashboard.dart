import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/synergy/synergy_manager.dart';
import '../hub/providers/hub_providers.dart';

/// Synergy dashboard showing all system interactions
class SynergyDashboard extends ConsumerStatefulWidget {
  const SynergyDashboard({super.key});

  @override
  ConsumerState<SynergyDashboard> createState() => _SynergyDashboardState();
}

class _SynergyDashboardState extends ConsumerState<SynergyDashboard> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final blockchain = ref.read(blockchainProvider);
    final nostrClient = ref.read(nostrClientProvider);
    final hdpManager = ref.read(hdpManagerProvider);
    final openclManager = OpenCLManager();

    await openclManager.initialize();

    final synergyManager = SynergyManager(
      blockchain: blockchain,
      nostrClient: nostrClient,
      hdpManager: hdpManager,
      openclManager: openclManager,
    );

    final stats = await synergyManager.getSynergyStats();

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synergy Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_stats == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSynergyOverview(),
            const SizedBox(height: 24),
            _buildBlockchainStats(),
            const SizedBox(height: 24),
            _buildNostrStats(),
            const SizedBox(height: 24),
            _buildComputeStats(),
            const SizedBox(height: 24),
            _buildSynergyMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildSynergyOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Synergy Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'All systems are working together to create a powerful, decentralized hub.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainStats() {
    final blockchain = _stats!['blockchain'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Blockchain',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Blocks', blockchain['totalBlocks'].toString()),
            _buildStatRow('Token Mints', blockchain['tokenMints'].toString()),
            _buildStatRow('Token Usage', blockchain['tokenUsages'].toString()),
            _buildStatRow('Chain Valid', blockchain['isValid'] ? '✓ Yes' : '✗ No'),
          ],
        ),
      ),
    );
  }

  Widget _buildNostrStats() {
    final nostr = _stats!['nostr'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'NOSTR Network',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Connected Relays', nostr['connectedRelays'].toString()),
            _buildStatRow('Active Connections', nostr['activeConnections'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildComputeStats() {
    final compute = _stats!['compute'] as Map<String, dynamic>;
    final devices = compute['devices'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.memory, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Compute Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Devices', devices.length.toString()),
            ...devices.map((device) => _buildDeviceRow(device as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildSynergyMetrics() {
    final synergies = _stats!['synergies'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Synergy Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Blockchain Identities', synergies['totalIdentities'].toString()),
            _buildStatRow('Total Rewards', '${synergies['totalRewards']} PYREAL'),
            _buildStatRow('Marketplace Apps', synergies['marketplaceListings'].toString()),
            _buildStatRow('Verified NOSTR Events', synergies['verifiedNostrEvents'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(Map<String, dynamic> device) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(device['type'] as String),
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              device['name'] as String,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${device['computeUnits']} CUs',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'gpu':
        return Icons.videogame_asset;
      case 'cpu':
        return Icons.computer;
      default:
        return Icons.memory;
    }
  }
}
