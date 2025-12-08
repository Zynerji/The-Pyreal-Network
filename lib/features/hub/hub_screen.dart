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

    // Ensure currentTab is within bounds
    final safeCurrentTab = filteredTokens.isNotEmpty
        ? currentTab.clamp(0, filteredTokens.length - 1)
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top tab bar
            AppTabBar(
              tokens: filteredTokens,
              currentIndex: safeCurrentTab,
              onTabChanged: (index) {
                ref.read(currentTabProvider.notifier).state = index;
              },
              onAddTab: () => _showAddTokenDialog(context, activeWidgeToken.targetType),
              onCloseTab: (index) {
                if (index < filteredTokens.length) {
                  ref.read(hubManagerProvider.notifier).removeAppToken(
                    filteredTokens[index].id,
                  );
                  // Adjust currentTab if needed
                  if (safeCurrentTab >= filteredTokens.length - 1 && safeCurrentTab > 0) {
                    ref.read(currentTabProvider.notifier).state = safeCurrentTab - 1;
                  }
                }
              },
            ),

            // Main canvas area
            Expanded(
              child: AppCanvas(
                token: filteredTokens.isNotEmpty ? filteredTokens[safeCurrentTab] : null,
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
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final credentialsController = TextEditingController(text: '{}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type.name} Token'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  hintText: 'My App',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: credentialsController,
                decoration: const InputDecoration(
                  labelText: 'Credentials (JSON)',
                  border: OutlineInputBorder(),
                  hintText: '{"username": "...", "password": "..."}',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              urlController.dispose();
              credentialsController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate inputs
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              if (urlController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a URL')),
                );
                return;
              }

              // Parse credentials JSON
              Map<String, dynamic> credentials = {};
              try {
                credentials = {};
                // In production, parse actual JSON from credentialsController.text
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $e')),
                  );
                  return;
                }
              }

              // Mint the token
              try {
                await ref.read(hubManagerProvider.notifier).mintAppToken(
                  name: nameController.text,
                  type: type,
                  url: urlController.text,
                  credentials: credentials,
                  userId: 'default_user', // In production, get from auth
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Token "${nameController.text}" minted successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error minting token: $e')),
                  );
                }
              } finally {
                nameController.dispose();
                urlController.dispose();
                credentialsController.dispose();
              }
            },
            child: const Text('Mint Token'),
          ),
        ],
      ),
    );
  }
}
