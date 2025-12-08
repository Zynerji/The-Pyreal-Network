import 'package:flutter/material.dart';
import '../../../core/tokens/widge_token.dart';

/// Bottom workbar with widget buttons for switching app types
class Workbar extends StatelessWidget {
  final List<WidgeToken> widgeTokens;
  final WidgeToken activeToken;
  final Function(WidgeToken) onWidgeSelected;

  const Workbar({
    super.key,
    required this.widgeTokens,
    required this.activeToken,
    required this.onWidgeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widgeTokens.map((token) {
          final isActive = token.id == activeToken.id;

          return _WorkbarButton(
            token: token,
            isActive: isActive,
            onTap: () => onWidgeSelected(token),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkbarButton extends StatelessWidget {
  final WidgeToken token;
  final bool isActive;
  final VoidCallback onTap;

  const _WorkbarButton({
    required this.token,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // color: isActive ? token.color.withOpacity(0.2) : Colors.transparent, // Disabled: WidgeToken has no color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.extension, // Default icon used
                size: 28,
                color: Colors.grey[500], // Default color, WidgeToken has no color
              ),
            ),
            const SizedBox(height: 4),
            Text(
              token.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500], // Default color, WidgeToken has no color
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
