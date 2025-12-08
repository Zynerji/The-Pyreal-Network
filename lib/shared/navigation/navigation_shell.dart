import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/hub/hub_screen.dart';
import '../../features/synergy/synergy_dashboard.dart';
import '../../features/ai/ai_marketplace_screen.dart';
import '../../features/safety/content_safety_screen.dart';
import '../../features/orchestration/hypervisor_monitor_screen.dart';
import '../../features/conductor/conductor_chat_screen.dart';
import 'app_navigation.dart';

/// Main navigation shell for the application
/// Provides bottom navigation bar and drawer access
class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HubScreen(),
    SynergyDashboard(),
    AIMarketplaceScreen(),
    ContentSafetyScreen(),
    HypervisorMonitorScreen(),
    ConductorChatScreen(),
  ];

  final List<String> _titles = const [
    'Pyreal Hub',
    'Synergy Dashboard',
    'AI Marketplace',
    'Content Safety',
    'Hypervisor Monitor',
    'Conductor AI',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              _getIconForIndex(_currentIndex),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(_titles[_currentIndex]),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF0F0F1E),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      drawer: const PyrealDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: PyrealBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.hub;
      case 2:
        return Icons.smart_toy;
      case 3:
        return Icons.shield;
      case 4:
        return Icons.settings_system_daydream;
      case 5:
        return Icons.psychology;
      default:
        return Icons.dashboard;
    }
  }
}
