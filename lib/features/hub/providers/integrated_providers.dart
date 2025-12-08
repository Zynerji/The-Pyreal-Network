import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/model_marketplace.dart';
import '../../../core/api/compute_api.dart';
import '../../../core/orchestration/hypervisor.dart';
import '../../../core/orchestration/conductor_llm.dart';
import '../../../core/safety/content_safety.dart';
import '../../../core/synergy/synergy_manager.dart';
import '../../../core/blockchain/blockchain.dart';
import '../../../core/nostr/nostr_client.dart';
import '../../../core/hdp/hdp_manager.dart';
import '../../../core/compute/opencl_manager.dart';
import '../../../core/compute/compute_network.dart';
import 'hub_providers.dart';

/// Comprehensive integrated providers for all systems
/// This creates a deeply synergized, AAA-quality experience

// ============================================================================
// CORE SYSTEM PROVIDERS
// ============================================================================

/// OpenCL Manager - Compute device management
final openclManagerProvider = Provider<OpenCLManager>((ref) {
  final manager = OpenCLManager();
  ref.onDispose(() => manager.dispose());

  // Initialize on first access
  Future.microtask(() async {
    await manager.initialize();
  });

  return manager;
});

/// Compute Network - Distributed task distribution
final computeNetworkProvider = Provider<ComputeNetwork>((ref) {
  final openclManager = ref.watch(openclManagerProvider);
  return ComputeNetwork(openclManager: openclManager);
});

/// Synergy Manager - Central coordinator
final synergyManagerProvider = Provider<SynergyManager>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final nostrClient = ref.watch(nostrClientProvider);
  final hdpManager = ref.watch(hdpManagerProvider);
  final openclManager = ref.watch(openclManagerProvider);

  final manager = SynergyManager(
    blockchain: blockchain,
    nostrClient: nostrClient,
    hdpManager: hdpManager,
    openclManager: openclManager,
  );

  ref.onDispose(() => manager.dispose());

  return manager;
});

// ============================================================================
// ADVANCED FEATURE PROVIDERS
// ============================================================================

/// AI Model Marketplace - Choose between competing AI models
final aiMarketplaceProvider = Provider<AIModelMarketplace>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final openclManager = ref.watch(openclManagerProvider);

  return AIModelMarketplace(
    blockchain: blockchain,
    openclManager: openclManager,
  );
});

/// Active AI Model - Currently selected model
final activeAIModelProvider = StateProvider<String?>((ref) => null);

/// Compute API System - External API access
final computeAPIProvider = Provider<ComputeAPISystem>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final computeNetwork = ref.watch(computeNetworkProvider);

  return ComputeAPISystem(
    blockchain: blockchain,
    computeNetwork: computeNetwork,
  );
});

/// Compute Hypervisor - Resource orchestration
final hypervisorProvider = Provider<ComputeHypervisor>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final computeNetwork = ref.watch(computeNetworkProvider);

  final hypervisor = ComputeHypervisor(
    blockchain: blockchain,
    computeNetwork: computeNetwork,
  );

  // Start hypervisor automatically
  Future.microtask(() async {
    await hypervisor.start();
  });

  ref.onDispose(() => hypervisor.stop());

  return hypervisor;
});

/// Conductor LLM - Intelligent distributed AI orchestrator
final conductorProvider = Provider<ConductorLLM>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final hdpManager = ref.watch(hdpManagerProvider);
  final openclManager = ref.watch(openclManagerProvider);
  final nostrClient = ref.watch(nostrClientProvider);
  final hypervisor = ref.watch(hypervisorProvider);

  final conductor = ConductorLLM(
    blockchain: blockchain,
    hdpManager: hdpManager,
    openclManager: openclManager,
    nostrClient: nostrClient,
    hypervisor: hypervisor,
  );

  // Initialize conductor automatically
  Future.microtask(() async {
    await conductor.initialize();
  });

  ref.onDispose(() => conductor.dispose());

  return conductor;
});

/// Content Safety System - CSAM detection and reporting
final contentSafetyProvider = Provider<ContentSafetySystem>((ref) {
  final blockchain = ref.watch(blockchainProvider);
  final aiMarketplace = ref.watch(aiMarketplaceProvider);

  return ContentSafetySystem(
    blockchain: blockchain,
    aiMarketplace: aiMarketplace,
  );
});

// ============================================================================
// REAL-TIME STATE PROVIDERS
// ============================================================================

/// System Health Status - Real-time health monitoring
final systemHealthProvider = StreamProvider<Map<String, bool>>((ref) async* {
  final synergyManager = ref.watch(synergyManagerProvider);

  // Poll health status every 10 seconds
  while (true) {
    yield await synergyManager.healthCheck();
    await Future.delayed(const Duration(seconds: 10));
  }
});

/// Synergy Statistics - Real-time metrics
final synergyStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final synergyManager = ref.watch(synergyManagerProvider);

  // Update stats every 5 seconds
  while (true) {
    yield await synergyManager.getSynergyStats();
    await Future.delayed(const Duration(seconds: 5));
  }
});

/// Compute Network Stats - Real-time compute metrics
final computeNetworkStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final computeNetwork = ref.watch(computeNetworkProvider);

  // Update every 3 seconds
  while (true) {
    yield computeNetwork.getNetworkStats();
    await Future.delayed(const Duration(seconds: 3));
  }
});

/// Blockchain Stats - Real-time blockchain metrics
final blockchainStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final blockchain = ref.watch(blockchainProvider);

  // Update every 5 seconds
  while (true) {
    yield blockchain.getStats();
    await Future.delayed(const Duration(seconds: 5));
  }
});

// ============================================================================
// UI STATE PROVIDERS
// ============================================================================

/// Loading States - Global loading indicators
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error State - Global error handling
final errorProvider = StateProvider<String?>((ref) => null);

/// Success Message - Global success feedback
final successMessageProvider = StateProvider<String?>((ref) => null);

/// Active Feature - Current feature being used
enum ActiveFeature {
  hub,
  marketplace,
  aiModels,
  compute,
  safety,
  synergy,
}

final activeFeatureProvider = StateProvider<ActiveFeature>((ref) => ActiveFeature.hub);

// ============================================================================
// PERFORMANCE OPTIMIZATION PROVIDERS
// ============================================================================

/// Memoized AI Models - Cache AI model list
final aiModelsListProvider = Provider<List<AIModel>>((ref) {
  final marketplace = ref.watch(aiMarketplaceProvider);
  return marketplace.allModels;
});

/// Memoized Marketplace Stats
final marketplaceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final marketplace = ref.watch(aiMarketplaceProvider);
  return marketplace.getMarketplaceStats();
});

// ============================================================================
// ACTION PROVIDERS - User Actions
// ============================================================================

/// Select AI Model Action
final selectAIModelAction = Provider<Future<void> Function(String, String)>((ref) {
  return (String modelId, String userId) async {
    final marketplace = ref.read(aiMarketplaceProvider);
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      await marketplace.selectModel(modelId, userId);
      ref.read(activeAIModelProvider.notifier).state = modelId;
      ref.read(successMessageProvider.notifier).state = 'AI model selected successfully!';
    } catch (e) {
      ref.read(errorProvider.notifier).state = 'Failed to select model: $e';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  };
});

/// Run AI Inference Action
final runInferenceAction = Provider<Future<AIInferenceResult> Function(String, String)>((ref) {
  return (String userId, String prompt) async {
    final marketplace = ref.read(aiMarketplaceProvider);
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final result = await marketplace.runInference(
        userId: userId,
        prompt: prompt,
      );
      ref.read(successMessageProvider.notifier).state = 'Inference completed!';
      return result;
    } catch (e) {
      ref.read(errorProvider.notifier).state = 'Inference failed: $e';
      rethrow;
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  };
});

/// Scan Content for Safety Action
final scanContentAction = Provider<Future<SafetyCheckResult> Function(Map<String, dynamic>)>((ref) {
  return (Map<String, dynamic> params) async {
    final safety = ref.read(contentSafetyProvider);
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final result = await safety.scanContent(
        contentId: params['contentId'],
        contentType: params['contentType'],
        imageData: params['imageData'],
        textContent: params['textContent'],
        userId: params['userId'],
        metadata: params['metadata'] ?? {},
      );

      if (result.severity != ThreatSeverity.safe) {
        ref.read(errorProvider.notifier).state = 'Content flagged: ${result.severity.name}';
      } else {
        ref.read(successMessageProvider.notifier).state = 'Content is safe';
      }

      return result;
    } catch (e) {
      ref.read(errorProvider.notifier).state = 'Safety scan failed: $e';
      rethrow;
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  };
});
