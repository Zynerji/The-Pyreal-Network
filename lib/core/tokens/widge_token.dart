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
  // final IconData icon; // Disabled for code generation compatibility. Add custom JsonConverter if needed.

  @HiveField(3)
  final AppTokenType targetType;

  @HiveField(4)
  // final Color color; // Disabled for code generation compatibility. Add custom JsonConverter if needed.

  @HiveField(5)
  final int position;

  @HiveField(6)
  final bool isDefault;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  WidgeToken({
    required this.id,
    required this.name,
    // required this.icon, // Disabled for code generation compatibility
    required this.targetType,
    // required this.color, // Disabled for code generation compatibility
    required this.position,
    this.isDefault = false,
    this.metadata = const {},
  });

  factory WidgeToken.fromJson(Map<String, dynamic> json) => _$WidgeTokenFromJson(json);

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
      // icon: icon ?? this.icon, // Disabled for code generation compatibility
      targetType: targetType ?? this.targetType,
      // color: color ?? this.color, // Disabled for code generation compatibility
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
        // icon: Icons.people, // Disabled for code generation compatibility
        targetType: AppTokenType.nostrSocial,
        // color: const Color(0xFF8B5CF6), // Disabled for code generation compatibility
        position: 0,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_email',
        name: 'Email',
        // icon: Icons.email, // Disabled for code generation compatibility
        targetType: AppTokenType.email,
        // color: const Color(0xFF3B82F6), // Disabled for code generation compatibility
        position: 1,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_browser',
        name: 'Browser',
        // icon: Icons.language, // Disabled for code generation compatibility
        targetType: AppTokenType.browser,
        // color: const Color(0xFF10B981), // Disabled for code generation compatibility
        position: 2,
        isDefault: true,
      ),
      WidgeToken(
        id: 'wt_apps',
        name: 'Apps',
        // icon: Icons.apps, // Disabled for code generation compatibility
        targetType: AppTokenType.custom,
        // color: const Color(0xFFF59E0B), // Disabled for code generation compatibility
        position: 3,
        isDefault: true,
      ),
    ];
  }
}
