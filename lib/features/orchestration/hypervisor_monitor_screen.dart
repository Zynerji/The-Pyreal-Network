import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/orchestration/hypervisor.dart';
import '../../core/orchestration/conductor_llm.dart';
import '../../core/compute/device_type.dart';
import '../../shared/widgets/polished_widgets.dart';
import '../hub/providers/integrated_providers.dart';

/// Hypervisor Monitor - Real-time orchestration dashboard
/// Shows task scheduling, resource allocation, and system health
class HypervisorMonitorScreen extends ConsumerStatefulWidget {
  const HypervisorMonitorScreen({super.key});

  @override
  ConsumerState<HypervisorMonitorScreen> createState() => _HypervisorMonitorScreenState();
}

class _HypervisorMonitorScreenState extends ConsumerState<HypervisorMonitorScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Real-time updates every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hypervisor = ref.watch(hypervisorProvider);
    final conductor = ref.watch(conductorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hypervisor Orchestration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => _showAddTaskDialog(context, hypervisor),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSystemOverview(hypervisor),
              const SizedBox(height: 16),
              _buildConductorMetrics(conductor),
              const SizedBox(height: 16),
              _buildResourceAllocation(hypervisor),
              const SizedBox(height: 16),
              _buildActiveTasks(hypervisor),
              const SizedBox(height: 16),
              _buildUserQuotas(hypervisor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemOverview(Hypervisor hypervisor) {
    final stats = hypervisor.getStats();
    final activeTaskCount = stats['activeTasks'] as int;
    final queuedTaskCount = stats['queuedTasks'] as int;
    final totalAllocated = (stats['totalResourcesAllocated'] as num).toDouble();
    final totalAvailable = (stats['totalResourcesAvailable'] as num).toDouble();
    final utilizationPercent = totalAvailable > 0
        ? (totalAllocated / totalAvailable * 100).clamp(0, 100)
        : 0.0;

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: Colors.purple, size: 28),
              SizedBox(width: 12),
              Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Tasks',
                  activeTaskCount.toString(),
                  Icons.play_circle_filled,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Queued',
                  queuedTaskCount.toString(),
                  Icons.queue,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Allocated',
                  '${totalAllocated.toStringAsFixed(1)} CUs',
                  Icons.memory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Available',
                  '${totalAvailable.toStringAsFixed(1)} CUs',
                  Icons.computer,
                  Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Utilization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${utilizationPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getUtilizationColor(utilizationPercent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: utilizationPercent / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(
                    _getUtilizationColor(utilizationPercent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConductorMetrics(ConductorLLM conductor) {
    final metrics = conductor.getMetrics();
    final totalDecisions = metrics['totalDecisions'] as int? ?? 0;
    final batchedDecisions = metrics['batchedDecisions'] as int? ?? 0;
    final avgConfidence = (metrics['averageConfidence'] as num? ?? 0.0).toDouble();
    final learnedPatterns = metrics['learnedPatterns'] as int? ?? 0;
    final recentDecisions = metrics['recentDecisions'] as List? ?? [];

    // Idle compute metrics
    final idleCompute = metrics['idleCompute'] as Map<String, dynamic>? ?? {};
    final totalIdleTasks = idleCompute['totalIdleTasks'] as int? ?? 0;
    final totalIdleRevenue = (idleCompute['totalIdleRevenue'] as num? ?? 0.0).toDouble();

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.purple, size: 28),
              const SizedBox(width: 12),
              const Text(
                'AI Orchestrator (Conductor)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.visibility_off, size: 12, color: Colors.purple),
                    SizedBox(width: 4),
                    Text(
                      'Invisible',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Decisions',
                  totalDecisions.toString(),
                  Icons.auto_fix_high,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Confidence',
                  '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Learned',
                  '$learnedPatterns patterns',
                  Icons.school,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'ZK Batch',
                  '$batchedDecisions/100',
                  Icons.layers,
                  Colors.indigo,
                ),
              ),
            ],
          ),
          if (totalIdleTasks > 0) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.power, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Idle Compute Monetization',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${totalIdleRevenue.toStringAsFixed(1)} ₱ earned',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Idle Tasks',
                    totalIdleTasks.toString(),
                    Icons.archive,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Revenue',
                    '${totalIdleRevenue.toStringAsFixed(1)} ₱',
                    Icons.attach_money,
                    Colors.lime,
                  ),
                ),
              ],
            ),
          ],
          if (recentDecisions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Recent Decisions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recentDecisions.take(5).map((decision) {
              final taskId = decision['taskId'] as String? ?? 'unknown';
              final taskType = decision['taskType'] as String? ?? 'unknown';
              final device = decision['device'] as String? ?? 'unknown';
              final confidence = (decision['confidence'] as num? ?? 0.0).toDouble();
              final timestamp = decision['timestamp'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _showDecisionDetailsDialog(context, conductor, taskId),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      taskType.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _getDeviceIcon(device),
                                    size: 14,
                                    color: _getDeviceColor(device),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    device.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                taskId,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  confidence > 0.8 ? Icons.check_circle : Icons.info,
                                  size: 14,
                                  color: confidence > 0.8 ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(confidence * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: confidence > 0.8 ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceAllocation(Hypervisor hypervisor) {
    final allocation = hypervisor.getAllocation();

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Resource Allocation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allocation.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No resources allocated',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...allocation.entries.map((entry) {
              final deviceType = entry.key;
              final resources = entry.value as num;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getDeviceIcon(deviceType),
                              size: 20,
                              color: _getDeviceColor(deviceType),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              deviceType.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${resources.toStringAsFixed(1)} CUs',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (resources.toDouble() / 100).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation(
                          _getDeviceColor(deviceType),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActiveTasks(Hypervisor hypervisor) {
    final tasks = hypervisor.getActiveTasks();

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.task_alt, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Active Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length} running',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.grey[700]),
                    const SizedBox(height: 8),
                    Text(
                      'No active tasks',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.taskId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              _getDeviceIcon(task.deviceType.name),
                              size: 16,
                              color: _getDeviceColor(task.deviceType.name),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.requiredResources} CUs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          task.userId,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _getRunningTime(task.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildUserQuotas(Hypervisor hypervisor) {
    final quotas = hypervisor.getUserQuotas();

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'User Quotas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (quotas.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No user quotas set',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...quotas.entries.map((entry) {
              final userId = entry.key;
              final used = entry.value['used'] as num;
              final limit = entry.value['limit'] as num;
              final percent = (used / limit * 100).clamp(0, 100);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          userId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${used.toStringAsFixed(1)} / ${limit.toStringAsFixed(1)} CUs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation(
                          _getQuotaColor(percent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getUtilizationColor(double percent) {
    if (percent < 50) return Colors.green;
    if (percent < 80) return Colors.orange;
    return Colors.red;
  }

  Color _getQuotaColor(double percent) {
    if (percent < 70) return Colors.blue;
    if (percent < 90) return Colors.orange;
    return Colors.red;
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
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

  Color _getDeviceColor(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'gpu':
        return Colors.green;
      case 'cpu':
        return Colors.blue;
      case 'npu':
        return Colors.purple;
      case 'dsp':
        return Colors.orange;
      case 'isp':
        return Colors.pink;
      case 'videoprocessor':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _getRunningTime(DateTime start) {
    final duration = DateTime.now().difference(start);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showDecisionDetailsDialog(BuildContext context, ConductorLLM conductor, String taskId) {
    final decision = conductor.getDecisionReasoning(taskId);

    if (decision == null) {
      showErrorSnackbar(context, 'Decision details not found');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.purple),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Conductor Decision Reasoning'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Task ID', decision['taskId'] as String? ?? 'Unknown'),
                const SizedBox(height: 12),
                _buildDetailRow('Task Type', (decision['taskType'] as String? ?? 'unknown').toUpperCase()),
                const SizedBox(height: 12),
                _buildDetailRow('User ID', decision['userId'] as String? ?? 'Unknown'),
                const Divider(height: 24),
                _buildDetailRow('Recommended Device', (decision['device'] as String? ?? 'unknown').toUpperCase()),
                const SizedBox(height: 12),
                _buildDetailRow('Estimated Resources', '${decision['resources']} CUs'),
                const SizedBox(height: 12),
                _buildDetailRow('Priority', 'Level ${decision['priority']}'),
                const SizedBox(height: 12),
                _buildDetailRow('Duration', '${decision['duration']}s'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Confidence: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${((decision['confidence'] as num? ?? 0.0) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (decision['confidence'] as num? ?? 0.0) > 0.8
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Reasoning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    decision['reasoning'] as String? ?? 'No reasoning provided',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                ),
                if ((decision['suggestedNodes'] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Suggested Nodes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(decision['suggestedNodes'] as List).map((node) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          node.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                const SizedBox(height: 16),
                Text(
                  'Timestamp: ${_formatTimestamp(decision['timestamp'] as String? ?? '')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PremiumButton(
            text: 'Close',
            icon: Icons.check,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context, Hypervisor hypervisor) {
    final taskIdController = TextEditingController(text: 'task_${DateTime.now().millisecondsSinceEpoch}');
    final userIdController = TextEditingController(text: 'default_user');
    DeviceType selectedDevice = DeviceType.gpu;
    double resources = 10.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskIdController,
                  decoration: const InputDecoration(
                    labelText: 'Task ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DeviceType>(
                  value: selectedDevice,
                  decoration: const InputDecoration(
                    labelText: 'Device Type',
                    border: OutlineInputBorder(),
                  ),
                  items: DeviceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getDeviceIcon(type.name), size: 16),
                          const SizedBox(width: 8),
                          Text(type.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDevice = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Required Resources: ${resources.toStringAsFixed(1)} CUs'),
                    Slider(
                      value: resources,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (value) {
                        setDialogState(() => resources = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            PremiumButton(
              text: 'Schedule',
              icon: Icons.add_task,
              onPressed: () {
                final task = ComputeTask(
                  taskId: taskIdController.text,
                  userId: userIdController.text,
                  deviceType: selectedDevice,
                  requiredResources: resources,
                  priority: 1,
                  timestamp: DateTime.now(),
                );

                final scheduled = hypervisor.scheduleTask(task);
                Navigator.pop(context);

                if (scheduled) {
                  showSuccessSnackbar(context, 'Task scheduled successfully');
                  setState(() {});
                } else {
                  showErrorSnackbar(context, 'Failed to schedule task - insufficient resources');
                }
              },
            ),
          ],
        ),
      ),
    );

    taskIdController.dispose();
    userIdController.dispose();
  }
}
