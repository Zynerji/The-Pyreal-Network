import 'package:flutter/material.dart';
import '../../features/hub/hub_screen.dart';
import '../../features/synergy/synergy_dashboard.dart';
import '../../features/ai/ai_marketplace_screen.dart';
import '../../features/safety/content_safety_screen.dart';
import '../../features/orchestration/hypervisor_monitor_screen.dart';
import '../../features/conductor/conductor_chat_screen.dart';

/// Central navigation for Pyreal Hub
/// Provides access to all major features with AAA-quality polish
class AppNavigation {
  static const String hub = '/';
  static const String synergy = '/synergy';
  static const String aiMarketplace = '/ai-marketplace';
  static const String contentSafety = '/content-safety';
  static const String hypervisor = '/hypervisor';
  static const String conductor = '/conductor';

  static Map<String, WidgetBuilder> get routes => {
        hub: (context) => const HubScreen(),
        synergy: (context) => const SynergyDashboard(),
        aiMarketplace: (context) => const AIMarketplaceScreen(),
        contentSafety: (context) => const ContentSafetyScreen(),
        hypervisor: (context) => const HypervisorMonitorScreen(),
        conductor: (context) => const ConductorChatScreen(),
      };

  static void navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  static void navigateToHub(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, hub, (route) => false);
  }
}

/// Premium navigation drawer with AAA-quality design
class PyrealDrawer extends StatelessWidget {
  const PyrealDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Hub',
                      subtitle: 'Main dashboard',
                      route: AppNavigation.hub,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.hub,
                      title: 'Synergy Dashboard',
                      subtitle: 'System interactions',
                      route: AppNavigation.synergy,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.psychology,
                      title: 'AI Marketplace',
                      subtitle: 'Choose AI models',
                      route: AppNavigation.aiMarketplace,
                      gradient: const [Color(0xFFD4A574), Color(0xFFCC9966)],
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.shield,
                      title: 'Content Safety',
                      subtitle: 'Scan uploads',
                      route: AppNavigation.contentSafety,
                      gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_system_daydream,
                      title: 'Hypervisor',
                      subtitle: 'Resource orchestration',
                      route: AppNavigation.hypervisor,
                      gradient: const [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.psychology,
                      title: 'Conductor',
                      subtitle: 'AI orchestrator chat',
                      route: AppNavigation.conductor,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    const Divider(height: 32),
                    _buildInfoSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub, size: 40, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'PYREAL HUB',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Decentralized Excellence',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required List<Color> gradient,
  }) {
    final isSelected = ModalRoute.of(context)?.settings.name == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (!isSelected) {
              AppNavigation.navigateTo(context, route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: gradient)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Colors.white24, Colors.white12],
                          )
                        : LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[300],
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Info',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle, 'All Systems Operational', Colors.green),
          _buildInfoRow(Icons.security, 'Content Safety Active', Colors.blue),
          _buildInfoRow(Icons.cloud_done, 'NOSTR Connected', Colors.green),
          _buildInfoRow(Icons.memory, 'Compute Ready', Colors.orange),
          const SizedBox(height: 16),
          Text(
            'v1.0.0 - AAA Quality',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar for quick access to main features
class PyrealBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PyrealBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.95),
            const Color(0xFF0F0F1E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 11,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub),
            label: 'Synergy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_system_daydream),
            label: 'System',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Conductor',
          ),
        ],
      ),
    );
  }
}
