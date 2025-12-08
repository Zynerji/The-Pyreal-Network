import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/tokens/app_token.dart';
import 'widgets/app_tab_bar.dart';
import 'widgets/app_canvas.dart';
import 'widgets/workbar.dart';
import 'providers/hub_providers.dart';

/// Main hub screen with tab canvas and bottom workbar
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  @override
  void initState() {
    super.initState();
    Future(() async {
      await ref.read(hubManagerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final appTokens = ref.watch(appTokensProvider);
    final activeWidgeToken = ref.watch(activeWidgeTokenProvider);

    // Filter tokens by current widge type
    final filteredTokens = appTokens.where(
      (token) => token.type == activeWidgeToken.targetType,
    ).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top tab bar
            AppTabBar(
              tokens: filteredTokens,
              currentIndex: currentTab,
              onTabChanged: (index) {
                ref.read(currentTabProvider.notifier).state = index;
              },
              onAddTab: () => _showAddTokenDialog(context, activeWidgeToken.targetType),
              onCloseTab: (index) {
                ref.read(hubManagerProvider.notifier).removeAppToken(
                  filteredTokens[index].id,
                );
              },
            ),

            // Main canvas area
            Expanded(
              child: AppCanvas(
                token: filteredTokens.isNotEmpty ? filteredTokens[currentTab] : null,
              ),
            ),

            // Bottom workbar
            Workbar(
              widgeTokens: ref.watch(widgeTokensProvider),
              activeToken: activeWidgeToken,
              onWidgeSelected: (widgeToken) {
                ref.read(activeWidgeTokenProvider.notifier).state = widgeToken;
                ref.read(currentTabProvider.notifier).state = 0;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTokenDialog(BuildContext context, AppTokenType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type.name} Token'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Credentials (JSON)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement token minting
              Navigator.pop(context);
            },
            child: const Text('Mint Token'),
          ),
        ],
      ),
    );
  }
}
