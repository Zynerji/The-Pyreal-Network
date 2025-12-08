import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/model_marketplace.dart';
import '../../shared/widgets/polished_widgets.dart';
import '../hub/providers/integrated_providers.dart';

/// AI Model Marketplace - Select and use competing AI models
/// AAA-quality UI with animations, haptic feedback, and real-time updates
class AIMarketplaceScreen extends ConsumerStatefulWidget {
  const AIMarketplaceScreen({super.key});

  @override
  ConsumerState<AIMarketplaceScreen> createState() => _AIMarketplaceScreenState();
}

class _AIMarketplaceScreenState extends ConsumerState<AIMarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedModelId;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = ref.watch(aiMarketplaceProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);
    final successMessage = ref.watch(successMessageProvider);

    // Show snackbars for errors and success
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
        title: const Text('AI Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'Models'),
            Tab(icon: Icon(Icons.chat), text: 'Inference'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModelsTab(marketplace),
          _buildInferenceTab(marketplace, isLoading),
          _buildStatsTab(marketplace),
        ],
      ),
    );
  }

  Widget _buildModelsTab(AIModelMarketplace marketplace) {
    final models = marketplace.getAvailableModels();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final isSelected = _selectedModelId == model.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedCard(
              elevation: isSelected ? 6.0 : 2.0,
              color: isSelected ? Colors.purple.withOpacity(0.1) : null,
              onTap: () {
                setState(() => _selectedModelId = model.id);
                ref.read(selectAIModelAction)(model.id, 'default_user');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getModelGradient(model.provider),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getModelIcon(model.capabilities.first),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  model.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              model.provider,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${model.costPerToken.toStringAsFixed(6)} tokens',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            '${model.tokensPerSecond} tok/s',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    model.description,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: model.capabilities.map((capability) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCapabilityIcon(capability),
                              size: 14,
                              color: Colors.purple[300],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              capability,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple[200],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInferenceTab(AIModelMarketplace marketplace, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedModelId == null)
            AnimatedCard(
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a model from the Models tab first',
                      style: TextStyle(color: Colors.orange[300]),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Run Inference',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _promptController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter your prompt here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumButton(
                    text: isLoading ? 'Running...' : 'Run Inference',
                    icon: Icons.play_arrow,
                    isLoading: isLoading,
                    onPressed: () => _runInference(marketplace),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Recommended for your task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildRecommendations(marketplace),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsTab(AIModelMarketplace marketplace) {
    final modelStats = marketplace.getModelUsageStats();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnimatedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Usage Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (modelStats.isEmpty)
                  Text(
                    'No usage data yet. Run some inferences to see stats!',
                    style: TextStyle(color: Colors.grey[400]),
                  )
                else
                  ...modelStats.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem(
                                'Calls',
                                entry.value['callCount'].toString(),
                                Icons.call_made,
                              ),
                              _buildStatItem(
                                'Tokens',
                                entry.value['totalTokens'].toString(),
                                Icons.token,
                              ),
                              _buildStatItem(
                                'Cost',
                                '${entry.value['totalCost'].toStringAsFixed(2)} PYREAL',
                                Icons.attach_money,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.purple[300]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecommendations(AIModelMarketplace marketplace) {
    final recommendations = [
      ('text', 'Text Generation'),
      ('code', 'Code Generation'),
      ('image', 'Image Generation'),
      ('reasoning', 'Complex Reasoning'),
    ];

    return recommendations.map((rec) {
      final model = marketplace.recommendModel(rec.$1);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(_getCapabilityIcon(rec.$1), size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(rec.$2, style: TextStyle(color: Colors.grey[300])),
              ],
            ),
            Text(
              model.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _runInference(AIModelMarketplace marketplace) async {
    if (_promptController.text.isEmpty) {
      showErrorSnackbar(context, 'Please enter a prompt');
      return;
    }

    if (_selectedModelId == null) {
      showErrorSnackbar(context, 'Please select a model first');
      return;
    }

    await ref.read(runInferenceAction)(
      _selectedModelId!,
      _promptController.text,
      'default_user',
    );
  }

  List<Color> _getModelGradient(String provider) {
    switch (provider.toLowerCase()) {
      case 'meta':
        return [const Color(0xFF0668E1), const Color(0xFF0A7AFF)];
      case 'anthropic':
        return [const Color(0xFFD4A574), const Color(0xFFCC9966)];
      case 'openai':
        return [const Color(0xFF10A37F), const Color(0xFF1A7F64)];
      case 'mistral':
        return [const Color(0xFFFF6B35), const Color(0xFFFF8C42)];
      case 'stability ai':
        return [const Color(0xFF7C3AED), const Color(0xFF9333EA)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFF6366F1)];
    }
  }

  IconData _getModelIcon(String capability) {
    switch (capability.toLowerCase()) {
      case 'text':
        return Icons.article;
      case 'code':
        return Icons.code;
      case 'reasoning':
        return Icons.psychology;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.smart_toy;
    }
  }

  IconData _getCapabilityIcon(String capability) {
    switch (capability.toLowerCase()) {
      case 'text':
        return Icons.text_fields;
      case 'code':
        return Icons.terminal;
      case 'reasoning':
        return Icons.lightbulb;
      case 'image':
        return Icons.photo;
      case 'audio':
        return Icons.mic;
      default:
        return Icons.star;
    }
  }
}
