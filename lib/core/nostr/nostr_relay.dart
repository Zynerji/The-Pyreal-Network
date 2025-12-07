/// Represents a NOSTR relay configuration
class NostrRelay {
  final String url;
  final String name;
  final bool read;
  final bool write;
  final Map<String, dynamic> metadata;

  NostrRelay({
    required this.url,
    required this.name,
    this.read = true,
    this.write = true,
    this.metadata = const {},
  });

  factory NostrRelay.fromJson(Map<String, dynamic> json) {
    return NostrRelay(
      url: json['url'],
      name: json['name'],
      read: json['read'] ?? true,
      write: json['write'] ?? true,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'read': read,
      'write': write,
      'metadata': metadata,
    };
  }

  /// Default NOSTR relays
  static List<NostrRelay> getDefaults() {
    return [
      NostrRelay(
        url: 'wss://relay.damus.io',
        name: 'Damus',
      ),
      NostrRelay(
        url: 'wss://nos.lol',
        name: 'Nos',
      ),
      NostrRelay(
        url: 'wss://relay.snort.social',
        name: 'Snort',
      ),
      NostrRelay(
        url: 'wss://relay.nostr.band',
        name: 'Nostr Band',
      ),
    ];
  }

  @override
  String toString() => 'NostrRelay($name: $url)';
}
