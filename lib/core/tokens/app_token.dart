import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_token.g.dart';

/// Represents an application token that can be loaded into a tab
/// Each AppToken is minted by the user with their credentials and stored
@HiveType(typeId: 0)
@JsonSerializable()
class AppToken {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final AppTokenType type;

  @HiveField(3)
  final String url;

  @HiveField(4)
  final Map<String, dynamic> credentials;

  @HiveField(5)
  final String iconPath;

  @HiveField(6)
  final DateTime mintedAt;

  @HiveField(7)
  final String userId;

  @HiveField(8)
  final Map<String, dynamic> metadata;

  @HiveField(9)
  final List<String> hdpFragments;

  @HiveField(10)
  final bool isDefault;

  AppToken({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.credentials,
    required this.iconPath,
    required this.mintedAt,
    required this.userId,
    this.metadata = const {},
    this.hdpFragments = const [],
    this.isDefault = false,
  });

  factory AppToken.fromJson(Map<String, dynamic> json) =>
      _$AppTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AppTokenToJson(this);

  AppToken copyWith({
    String? id,
    String? name,
    AppTokenType? type,
    String? url,
    Map<String, dynamic>? credentials,
    String? iconPath,
    DateTime? mintedAt,
    String? userId,
    Map<String, dynamic>? metadata,
    List<String>? hdpFragments,
    bool? isDefault,
  }) {
    return AppToken(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      credentials: credentials ?? this.credentials,
      iconPath: iconPath ?? this.iconPath,
      mintedAt: mintedAt ?? this.mintedAt,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      hdpFragments: hdpFragments ?? this.hdpFragments,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Types of applications that can be tokenized
@HiveType(typeId: 1)
enum AppTokenType {
  @HiveField(0)
  nostrSocial,

  @HiveField(1)
  email,

  @HiveField(2)
  socialMedia,

  @HiveField(3)
  browser,

  @HiveField(4)
  custom,

  @HiveField(5)
  tikTok,

  @HiveField(6)
  instagram,

  @HiveField(7)
  twitter,

  @HiveField(8)
  facebook,

  @HiveField(9)
  youtube,
}
