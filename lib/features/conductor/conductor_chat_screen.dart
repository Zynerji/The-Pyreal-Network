import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/orchestration/conductor_llm.dart';
import '../../core/orchestration/hypervisor.dart';
import '../../shared/widgets/polished_widgets.dart';
import '../hub/providers/hub_providers.dart';

/// Conductor Chat Interface
/// Natural language interaction with the distributed LLM orchestrator
class ConductorChatScreen extends ConsumerStatefulWidget {
  const ConductorChatScreen({super.key});

  @override
  ConsumerState<ConductorChatScreen> createState() => _ConductorChatScreenState();
}

class _ConductorChatScreenState extends ConsumerState<ConductorChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  ConductorLLM? _conductor;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _initializeConductor();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _conductor?.dispose();
    super.dispose();
  }

  Future<void> _initializeConductor() async {
    setState(() => _isProcessing = true);

    try {
      final blockchain = ref.read(blockchainProvider);
      final nostrClient = ref.read(nostrClientProvider);
      final hdpManager = ref.read(hdpManagerProvider);
      final openclManager = ref.read(openclManagerProvider);
      final hypervisor = ref.read(hypervisorProvider);

      _conductor = ConductorLLM(
        blockchain: blockchain,
        hdpManager: hdpManager,
        openclManager: openclManager,
        nostrClient: nostrClient,
        hypervisor: hypervisor,
      );

      await _conductor!.initialize();

      setState(() {
        _isInitialized = true;
        _messages.add(ChatMessage(
          text: '🎭 Hello! I\'m the Conductor, your distributed AI orchestrator. I run across the entire compute network to intelligently manage resources.\n\nYou can:\n• Ask me to schedule tasks\n• Query system status\n• Request performance analysis\n• Get recommendations\n\nHow can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      showSuccessSnackbar(context, 'Conductor initialized successfully!');
    } catch (e) {
      showErrorSnackbar(context, 'Failed to initialize Conductor: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_isInitialized || _isProcessing) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Check if it's a task scheduling request
      if (text.toLowerCase().contains('schedule') ||
          text.toLowerCase().contains('run') ||
          text.toLowerCase().contains('execute')) {
        await _handleTaskScheduling(text);
      } else {
        // General query
        final response = await _conductor!.query(text);
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '❌ Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleTaskScheduling(String text) async {
    final decision = await _conductor!.conductTask(
      taskDescription: text,
      taskMetadata: {
        'taskId': 'user_task_${DateTime.now().millisecondsSinceEpoch}',
        'source': 'conductor_chat',
      },
      userId: 'default_user',
    );

    final response = '''
✨ Task Analysis Complete

📋 Task: ${decision.taskDescription}

🎯 Recommendations:
• Device Type: ${decision.recommendedDeviceType.name.toUpperCase()}
• Resources: ${decision.estimatedResources} compute units
• Priority: ${decision.priority}
• Est. Duration: ~${decision.estimatedDuration.inSeconds}s

💭 Reasoning:
${decision.reasoning}

🎲 Confidence: ${(decision.confidence * 100).toStringAsFixed(1)}%

🌐 Suggested Nodes:
${decision.suggestedNodes.map((n) => '  • $n').join('\n')}

Would you like me to proceed with scheduling this task?
''';

    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        decision: decision,
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
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
              child: const Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conductor', style: TextStyle(fontSize: 18)),
                  Text(
                    'Distributed AI Orchestrator',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_isInitialized)
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showConductorInfo,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStats,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isInitialized)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const GlowingProgress(color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Initializing Conductor across the network...',
                      style: TextStyle(color: Colors.orange[300]),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: GlowingProgress(color: Colors.purple),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: AnimatedCard(
              color: message.isUser
                  ? const Color(0xFF2A2A3E)
                  : message.isError
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF1A1A2E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: message.isError ? Colors.red[300] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (message.decision != null)
                        TextButton.icon(
                          icon: const Icon(Icons.info_outline, size: 14),
                          label: const Text('Details', style: TextStyle(fontSize: 11)),
                          onPressed: () => _showDecisionDetails(message.decision!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person, color: Colors.white70, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: _isInitialized && !_isProcessing,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask the Conductor...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  suffixIcon: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isInitialized && !_isProcessing ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showConductorInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.purple),
            SizedBox(width: 12),
            Text('About the Conductor'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The Conductor is a tiny LLM (TinyLlama-1.1B) that runs distributedly across the compute network.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.hub,
                'Distributed Architecture',
                'Model weights stored via HDP, inference across multiple nodes',
              ),
              _buildInfoItem(
                Icons.psychology,
                'Intelligent Orchestration',
                'Natural language understanding for smart resource allocation',
              ),
              _buildInfoItem(
                Icons.speed,
                'Learning System',
                'Improves decisions based on historical performance',
              ),
              _buildInfoItem(
                Icons.security,
                'Blockchain Verified',
                'All decisions recorded on-chain for transparency',
              ),
            ],
          ),
        ),
        actions: [
          PremiumButton(
            text: 'Got it',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showStats() {
    if (_conductor == null) return;

    final stats = _conductor!.getStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conductor Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Status', stats['initialized'] ? '✅ Online' : '❌ Offline'),
            _buildStatRow('Model', stats['modelName']),
            _buildStatRow('Decisions', stats['decisionsCount'].toString()),
            _buildStatRow(
              'Avg Confidence',
              '${(stats['averageConfidence'] * 100).toStringAsFixed(1)}%',
            ),
            _buildStatRow('Active Nodes', stats['nodePerformance'].length.toString()),
          ],
        ),
        actions: [
          PremiumButton(
            text: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDecisionDetails(ConductorDecision decision) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decision Details'),
        content: SingleChildScrollView(
          child: Text(_conductor!.explainDecision(decision.taskId)),
        ),
        actions: [
          PremiumButton(
            text: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.purple[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final ConductorDecision? decision;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.decision,
  });
}
