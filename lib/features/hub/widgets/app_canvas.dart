import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/tokens/app_token.dart';
import '../../social/nostr_feed_view.dart';

/// Main canvas area for displaying app content
class AppCanvas extends StatefulWidget {
  final AppToken? token;

  const AppCanvas({
    super.key,
    this.token,
  });

  @override
  State<AppCanvas> createState() => _AppCanvasState();
}

class _AppCanvasState extends State<AppCanvas> {
  late WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void didUpdateWidget(AppCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token?.url != widget.token?.url) {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    if (widget.token != null && widget.token!.type != AppTokenType.nostrSocial) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.token!.url));
    } else {
      _webViewController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) {
      return _buildEmptyState();
    }

    // Special handling for NOSTR social feed
    if (widget.token!.type == AppTokenType.nostrSocial) {
      return NostrFeedView(token: widget.token!);
    }

    // WebView for other apps
    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tab,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No tabs open',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click + to add a new tab',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
