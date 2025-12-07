import 'package:flutter/material.dart';
import '../../../core/tokens/app_token.dart';

/// Top tab bar for displaying and managing app tokens
class AppTabBar extends StatelessWidget {
  final List<AppToken> tokens;
  final int currentIndex;
  final Function(int) onTabChanged;
  final VoidCallback onAddTab;
  final Function(int) onCloseTab;

  const AppTabBar({
    super.key,
    required this.tokens,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onAddTab,
    required this.onCloseTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tokens.length,
              itemBuilder: (context, index) {
                final token = tokens[index];
                final isActive = index == currentIndex;

                return _TabItem(
                  token: token,
                  isActive: isActive,
                  onTap: () => onTabChanged(index),
                  onClose: () => onCloseTab(index),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAddTab,
            tooltip: 'Add new tab',
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final AppToken token;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.token,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[800] : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForType(token.type),
              size: 16,
              color: isActive ? Colors.white : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                token.name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (!token.isDefault)
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(AppTokenType type) {
    switch (type) {
      case AppTokenType.nostrSocial:
        return Icons.people;
      case AppTokenType.email:
        return Icons.email;
      case AppTokenType.browser:
        return Icons.language;
      case AppTokenType.tikTok:
      case AppTokenType.instagram:
      case AppTokenType.twitter:
      case AppTokenType.facebook:
      case AppTokenType.youtube:
      case AppTokenType.socialMedia:
        return Icons.share;
      case AppTokenType.custom:
        return Icons.apps;
    }
  }
}
