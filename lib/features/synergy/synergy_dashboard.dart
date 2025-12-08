import '../../core/compute/opencl_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/synergy/synergy_manager.dart';
import '../../shared/widgets/polished_widgets.dart';
import '../hub/providers/hub_providers.dart';
import '../hub/providers/integrated_providers.dart';

/// Synergy dashboard showing all system interactions
/// Enhanced with AAA-quality polish and real-time updates
class SynergyDashboard extends ConsumerStatefulWidget {
  const SynergyDashboard({super.key});

  @override
  ConsumerState<SynergyDashboard> createState() => _SynergyDashboardState();
}

class _SynergyDashboardState extends ConsumerState<SynergyDashboard> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadStats();

    // Auto-refresh every 5 seconds for real-time feel
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isLoading) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
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

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(errorProvider);
    final successMessage = ref.watch(successMessageProvider);

    // Show snackbars
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorSnackbar(context, error);
        ref.read(errorProvider.notifier).state = null;
      });
    }

    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSuccessSnackbar(context, successMessage);
        ref.read(successMessageProvider.notifier).state = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Synergy Dashboard'),
            const SizedBox(width: 12),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FadeTransition(
                opacity: _pulseController,
                child: const Icon(Icons.fiber_manual_record, size: 12, color: Colors.green),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _demonstrateSynergies(),
            tooltip: 'Demonstrate Synergies',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _stats == null
          ? Center(child: GlowingProgress(color: Colors.purple))
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
    return AnimatedCard(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synergy Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Unified Decentralized Hub',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FadeTransition(
                opacity: _pulseController,
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'All systems are working together to create a powerful, decentralized hub. Real-time monitoring and AAA-quality interactions.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainStats() {
    final blockchain = _stats!['blockchain'] as Map<String, dynamic>;
    final isValid = blockchain['isValid'] as bool;

    return AnimatedCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Blockchain',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isValid ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isValid ? Colors.green : Colors.red).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: isValid ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isValid ? 'Valid' : 'Invalid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Blocks', blockchain['totalBlocks'].toString(), Icons.inventory_2),
          _buildStatRow('Token Mints', blockchain['tokenMints'].toString(), Icons.add_circle),
          _buildStatRow('Token Usage', blockchain['tokenUsages'].toString(), Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildNostrStats() {
    final nostr = _stats!['nostr'] as Map<String, dynamic>;
    final activeConnections = nostr['activeConnections'] as int;
    final connectedRelays = nostr['connectedRelays'] as int;

    return AnimatedCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NOSTR Network',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (activeConnections > 0)
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_done, color: Colors.green, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Connected Relays', connectedRelays.toString(), Icons.dns),
          _buildStatRow('Active Connections', activeConnections.toString(), Icons.signal_cellular_alt),
        ],
      ),
    );
  }

  Widget _buildComputeStats() {
    final compute = _stats!['compute'] as Map<String, dynamic>;
    final devices = compute['devices'] as List? ?? [];

    return AnimatedCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.memory, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Compute Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${devices.length} devices',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'No compute devices detected',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            ...devices.map((device) => _buildDeviceRow(device as Map<String, dynamic>)),
          ],
        ],
      ),
    );
  }

  Widget _buildSynergyMetrics() {
    final synergies = _stats!['synergies'] as Map<String, dynamic>;

    return AnimatedCard(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Synergy Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Blockchain Identities', synergies['totalIdentities'].toString(), Icons.fingerprint),
          _buildStatRow('Total Rewards', '${synergies['totalRewards']} PYREAL', Icons.monetization_on),
          _buildStatRow('Marketplace Apps', synergies['marketplaceListings'].toString(), Icons.store),
          _buildStatRow('Verified NOSTR Events', synergies['verifiedNostrEvents'].toString(), Icons.verified),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
    switch (type.toLowerCase()) {
      case 'gpu':
        return Icons.videogame_asset;
      case 'cpu':
        return Icons.computer;
      case 'npu':
        return Icons.psychology;
      case 'dsp':
        return Icons.graphic_eq;
      case 'isp':
        return Icons.camera;
      case 'videoprocessor':
        return Icons.video_library;
      default:
        return Icons.memory;
    }
  }

  Future<void> _demonstrateSynergies() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlowingProgress(color: Colors.purple, size: 60),
            const SizedBox(height: 24),
            const Text(
              'Demonstrating All Synergies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Creating identity, earning rewards, listing apps...',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
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

      await synergyManager.demonstrateSynergies();

      if (mounted) {
        Navigator.pop(context);
        showSuccessSnackbar(context, 'All synergies demonstrated successfully!');
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorSnackbar(context, 'Failed to demonstrate synergies: $e');
      }
    }
  }
}
