import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'app_token.dart';

part 'widge_token.g.dart';

/// Represents a widget button on the bottom workbar
/// WidgeTokens switch the view to display different types of AppTokens
@HiveType(typeId: 2)
@JsonSerializable()
class WidgeToken {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final IconData icon;

  @HiveField(3)
  final AppTokenType targetType;

  @HiveField(4)
  final Color color;

  @HiveField(5)
  final int position;

  @HiveField(6)
  final bool isDefault;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  WidgeToken({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetType,
    required this.color,
    required this.position,
    this.isDefault = false,
    this.metadata = const {},
  });

  factory WidgeToken.fromJson(Map<String, dynamic> json) =>
      _$WidgeTokenFromJson(json);

  Map<String, dynamic> toJson() => _$WidgeTokenToJson(this);

  WidgeToken copyWith({
    String? id,
    String? name,
    IconData? icon,
    AppTokenType? targetType,
    Color? color,
    int? position,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) {
    return WidgeToken(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetType: targetType ?? this.targetType,
      color: color ?? this.color,
      position: position ?? this.position,
      isDefault: isDefault ?? this.isDefault,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Default WidgeTokens for common functionalities
  static List<WidgeToken> getDefaults() {
    return [
      WidgeToken(
        id: 'wt_social',
        name: 'Social',
        icon: Icons.people,
        targetType: AppTokenType.nostrSocial,
        color: const Color(0xFF8B5CF6),
        position: 0,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_email',
        name: 'Email',
        icon: Icons.email,
        targetType: AppTokenType.email,
        color: const Color(0xFF3B82F6),
        position: 1,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_browser',
        name: 'Browser',
        icon: Icons.language,
        targetType: AppTokenType.browser,
        color: const Color(0xFF10B981),
        position: 2,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_apps',
        name: 'Apps',
        icon: Icons.apps,
        targetType: AppTokenType.custom,
        color: const Color(0xFFF59E0B),
        position: 3,
        isDefault: true,
      ),
    ];
  }
}
