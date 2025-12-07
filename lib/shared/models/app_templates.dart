import '../../core/tokens/app_token.dart';

/// Pre-made templates for popular social media apps
class AppTemplates {
  /// Get all available templates
  static List<AppTokenTemplate> getAll() {
    return [
      nostrTemplate,
      twitterTemplate,
      instagramTemplate,
      tikTokTemplate,
      facebookTemplate,
      youtubeTemplate,
      emailTemplate,
      browserTemplate,
    ];
  }

  /// NOSTR social feed template
  static AppTokenTemplate nostrTemplate = AppTokenTemplate(
    name: 'NOSTR Feed',
    type: AppTokenType.nostrSocial,
    description: 'Decentralized social media feed',
    url: '',
    iconPath: 'assets/images/nostr.png',
    credentialFields: [],
    isDefault: true,
  );

  /// Twitter (X) template
  static AppTokenTemplate twitterTemplate = AppTokenTemplate(
    name: 'X (Twitter)',
    type: AppTokenType.twitter,
    description: 'Twitter/X social media',
    url: 'https://twitter.com',
    iconPath: 'assets/images/twitter.png',
    credentialFields: [
      CredentialField(
        name: 'username',
        label: 'Username',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
    ],
  );

  /// Instagram template
  static AppTokenTemplate instagramTemplate = AppTokenTemplate(
    name: 'Instagram',
    type: AppTokenType.instagram,
    description: 'Instagram social media',
    url: 'https://instagram.com',
    iconPath: 'assets/images/instagram.png',
    credentialFields: [
      CredentialField(
        name: 'username',
        label: 'Username',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
    ],
  );

  /// TikTok template
  static AppTokenTemplate tikTokTemplate = AppTokenTemplate(
    name: 'TikTok',
    type: AppTokenType.tikTok,
    description: 'TikTok short video platform',
    url: 'https://tiktok.com',
    iconPath: 'assets/images/tiktok.png',
    credentialFields: [
      CredentialField(
        name: 'phone',
        label: 'Phone/Email/Username',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
    ],
  );

  /// Facebook template
  static AppTokenTemplate facebookTemplate = AppTokenTemplate(
    name: 'Facebook',
    type: AppTokenType.facebook,
    description: 'Facebook social network',
    url: 'https://facebook.com',
    iconPath: 'assets/images/facebook.png',
    credentialFields: [
      CredentialField(
        name: 'email',
        label: 'Email or Phone',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
    ],
  );

  /// YouTube template
  static AppTokenTemplate youtubeTemplate = AppTokenTemplate(
    name: 'YouTube',
    type: AppTokenType.youtube,
    description: 'YouTube video platform',
    url: 'https://youtube.com',
    iconPath: 'assets/images/youtube.png',
    credentialFields: [
      CredentialField(
        name: 'email',
        label: 'Google Email',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
    ],
  );

  /// Email template
  static AppTokenTemplate emailTemplate = AppTokenTemplate(
    name: 'Email',
    type: AppTokenType.email,
    description: 'Email client',
    url: '',
    iconPath: 'assets/images/email.png',
    credentialFields: [
      CredentialField(
        name: 'email',
        label: 'Email Address',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'password',
        label: 'Password',
        type: FieldType.password,
        required: true,
      ),
      CredentialField(
        name: 'server',
        label: 'IMAP Server',
        type: FieldType.text,
        required: true,
      ),
      CredentialField(
        name: 'port',
        label: 'Port',
        type: FieldType.number,
        required: true,
      ),
    ],
  );

  /// Browser template
  static AppTokenTemplate browserTemplate = AppTokenTemplate(
    name: 'Web Browser',
    type: AppTokenType.browser,
    description: 'General web browser',
    url: 'https://google.com',
    iconPath: 'assets/images/browser.png',
    credentialFields: [],
  );

  /// Get template by type
  static AppTokenTemplate? getByType(AppTokenType type) {
    try {
      return getAll().firstWhere((t) => t.type == type);
    } catch (e) {
      return null;
    }
  }
}

/// Template for creating app tokens
class AppTokenTemplate {
  final String name;
  final AppTokenType type;
  final String description;
  final String url;
  final String iconPath;
  final List<CredentialField> credentialFields;
  final bool isDefault;

  AppTokenTemplate({
    required this.name,
    required this.type,
    required this.description,
    required this.url,
    required this.iconPath,
    required this.credentialFields,
    this.isDefault = false,
  });
}

/// Credential field definition
class CredentialField {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final String? placeholder;
  final String? helpText;

  CredentialField({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.helpText,
  });
}

enum FieldType {
  text,
  password,
  email,
  number,
  url,
}
