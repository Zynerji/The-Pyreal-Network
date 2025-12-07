import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'nostr_event.dart';
import 'nostr_relay.dart';

/// NOSTR client implementation
/// Handles connections to NOSTR relays and event management
class NostrClient {
  final List<NostrRelay> _relays = [];
  final Map<String, WebSocketChannel> _connections = {};
  final StreamController<NostrEvent> _eventController = StreamController.broadcast();
  final Logger _logger = Logger();

  Stream<NostrEvent> get events => _eventController.stream;

  /// Add a relay to connect to
  void addRelay(NostrRelay relay) {
    if (!_relays.any((r) => r.url == relay.url)) {
      _relays.add(relay);
      _logger.i('Added relay: ${relay.url}');
    }
  }

  /// Remove a relay
  void removeRelay(String url) {
    _relays.removeWhere((r) => r.url == url);
    disconnect(url);
    _logger.i('Removed relay: $url');
  }

  /// Connect to a specific relay
  Future<bool> connect(String url) async {
    try {
      if (_connections.containsKey(url)) {
        _logger.w('Already connected to $url');
        return true;
      }

      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);

      _connections[url] = channel;

      channel.stream.listen(
        (message) => _handleMessage(url, message),
        onError: (error) => _handleError(url, error),
        onDone: () => _handleDisconnect(url),
      );

      _logger.i('Connected to relay: $url');
      return true;
    } catch (e) {
      _logger.e('Failed to connect to $url: $e');
      return false;
    }
  }

  /// Disconnect from a specific relay
  void disconnect(String url) {
    final channel = _connections.remove(url);
    channel?.sink.close();
    _logger.i('Disconnected from relay: $url');
  }

  /// Connect to all relays
  Future<void> connectAll() async {
    for (final relay in _relays) {
      await connect(relay.url);
    }
  }

  /// Disconnect from all relays
  void disconnectAll() {
    for (final url in _connections.keys.toList()) {
      disconnect(url);
    }
  }

  /// Publish an event to all connected relays
  Future<void> publish(NostrEvent event) async {
    final message = jsonEncode(['EVENT', event.toJson()]);

    for (final entry in _connections.entries) {
      try {
        entry.value.sink.add(message);
        _logger.d('Published event to ${entry.key}');
      } catch (e) {
        _logger.e('Failed to publish to ${entry.key}: $e');
      }
    }
  }

  /// Subscribe to events matching filters
  String subscribe(Map<String, dynamic> filters) {
    final subscriptionId = _generateSubscriptionId();
    final message = jsonEncode(['REQ', subscriptionId, filters]);

    for (final entry in _connections.entries) {
      try {
        entry.value.sink.add(message);
        _logger.d('Subscribed on ${entry.key} with ID: $subscriptionId');
      } catch (e) {
        _logger.e('Failed to subscribe on ${entry.key}: $e');
      }
    }

    return subscriptionId;
  }

  /// Unsubscribe from a subscription
  void unsubscribe(String subscriptionId) {
    final message = jsonEncode(['CLOSE', subscriptionId]);

    for (final entry in _connections.entries) {
      try {
        entry.value.sink.add(message);
        _logger.d('Unsubscribed from ${entry.key}: $subscriptionId');
      } catch (e) {
        _logger.e('Failed to unsubscribe from ${entry.key}: $e');
      }
    }
  }

  /// Handle incoming messages from relays
  void _handleMessage(String relayUrl, dynamic message) {
    try {
      final decoded = jsonDecode(message);

      if (decoded is List && decoded.isNotEmpty) {
        final type = decoded[0];

        switch (type) {
          case 'EVENT':
            if (decoded.length >= 3) {
              final event = NostrEvent.fromJson(decoded[2]);
              _eventController.add(event);
            }
            break;
          case 'NOTICE':
            _logger.i('Notice from $relayUrl: ${decoded[1]}');
            break;
          case 'EOSE':
            _logger.d('End of stored events from $relayUrl');
            break;
          default:
            _logger.w('Unknown message type from $relayUrl: $type');
        }
      }
    } catch (e) {
      _logger.e('Error handling message from $relayUrl: $e');
    }
  }

  /// Handle connection errors
  void _handleError(String relayUrl, dynamic error) {
    _logger.e('Error on relay $relayUrl: $error');
  }

  /// Handle relay disconnection
  void _handleDisconnect(String relayUrl) {
    _connections.remove(relayUrl);
    _logger.w('Relay disconnected: $relayUrl');
  }

  /// Generate unique subscription ID
  String _generateSubscriptionId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get connection status
  Map<String, bool> getConnectionStatus() {
    return Map.fromEntries(
      _relays.map((relay) => MapEntry(
        relay.url,
        _connections.containsKey(relay.url),
      )),
    );
  }

  /// Dispose resources
  void dispose() {
    disconnectAll();
    _eventController.close();
  }
}
