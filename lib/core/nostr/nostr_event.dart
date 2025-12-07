import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// NOSTR event model
/// Based on NIP-01 specification
class NostrEvent {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  NostrEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  /// Create a new unsigned event
  factory NostrEvent.create({
    required String pubkey,
    required int kind,
    required String content,
    List<List<String>>? tags,
  }) {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final eventTags = tags ?? [];

    final id = _calculateId(
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: eventTags,
      content: content,
    );

    return NostrEvent(
      id: id,
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: eventTags,
      content: content,
      sig: '', // To be signed
    );
  }

  /// Calculate event ID
  static String _calculateId({
    required String pubkey,
    required int createdAt,
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) {
    final serialized = jsonEncode([
      0, // Reserved for future use
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    ]);

    final bytes = utf8.encode(serialized);
    final hash = sha256.convert(bytes);
    return hex.encode(hash.bytes);
  }

  /// Create event from JSON
  factory NostrEvent.fromJson(Map<String, dynamic> json) {
    return NostrEvent(
      id: json['id'],
      pubkey: json['pubkey'],
      createdAt: json['created_at'],
      kind: json['kind'],
      tags: (json['tags'] as List)
          .map((tag) => (tag as List).map((e) => e.toString()).toList())
          .toList(),
      content: json['content'],
      sig: json['sig'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubkey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
    };
  }

  /// Verify event signature (simplified - real implementation needs schnorr signatures)
  bool verifySignature() {
    // In production, this would verify schnorr signatures
    // For now, just check if signature exists
    return sig.isNotEmpty;
  }

  /// Create a copy with updated fields
  NostrEvent copyWith({
    String? id,
    String? pubkey,
    int? createdAt,
    int? kind,
    List<List<String>>? tags,
    String? content,
    String? sig,
  }) {
    return NostrEvent(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      sig: sig ?? this.sig,
    );
  }

  @override
  String toString() {
    return 'NostrEvent(id: $id, kind: $kind, pubkey: ${pubkey.substring(0, 8)}...)';
  }
}

/// Common NOSTR event kinds
class NostrEventKind {
  static const int metadata = 0;
  static const int textNote = 1;
  static const int recommendRelay = 2;
  static const int contacts = 3;
  static const int encryptedDirectMessage = 4;
  static const int deletion = 5;
  static const int repost = 6;
  static const int reaction = 7;
  static const int channelCreation = 40;
  static const int channelMetadata = 41;
  static const int channelMessage = 42;
}
