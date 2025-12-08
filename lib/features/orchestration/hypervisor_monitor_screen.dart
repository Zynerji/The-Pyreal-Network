import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/orchestration/hypervisor.dart';
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
