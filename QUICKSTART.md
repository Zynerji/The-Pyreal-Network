# Pyreal Hub - Quick Start Guide

## Installation

### 1. Prerequisites

Ensure you have Flutter installed:
```bash
flutter doctor
```

You need Flutter 3.0.0 or higher.

### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/The-Pyreal-Network.git
cd The-Pyreal-Network

# Install dependencies
flutter pub get

# Generate code (for Hive adapters and JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App

```bash
# For desktop (Linux/macOS/Windows)
flutter run -d linux
flutter run -d macos
flutter run -d windows

# For mobile
flutter run -d android
flutter run -d ios

# For web
flutter run -d chrome
```

## First Launch

When you first launch Pyreal Hub, you'll see:

1. **Default NOSTR Feed**: A social media tab already loaded
2. **Bottom Workbar**: Four widgets (Social, Email, Browser, Apps)
3. **Empty Tab Bar**: Ready for you to add more apps

## Basic Usage

### Adding Your First App

1. Tap the **Social** widget at the bottom (purple icon)
2. Click the **+** button in the top tab bar
3. Choose a template (e.g., Twitter)
4. Fill in your credentials
5. Click **Mint Token**

Your app is now securely stored and ready to use!

### Switching Between Apps

- **Swipe or tap** tabs at the top to switch between open apps
- **Tap widgets** at the bottom to change categories

### Understanding Widgets

**Social Widget** (Purple):
- NOSTR Feed
- Twitter/X
- Instagram
- TikTok
- etc.

**Email Widget** (Blue):
- Email clients
- Will load your email apps

**Browser Widget** (Green):
- Web browsers
- General websites

**Apps Widget** (Orange):
- Custom applications
- Any other app type

## Key Features to Try

### 1. NOSTR Social Feed

The default NOSTR tab connects to multiple relays and shows real-time posts:

- See posts from the decentralized network
- Scroll to load more
- Pull to refresh

### 2. Token Minting

When you add credentials for an app:

1. **Encryption**: Your credentials are encrypted
2. **Fragmentation**: Split into holographic fragments
3. **Blockchain**: Recorded immutably
4. **Security**: No single point of failure

### 3. Compute Sharing (Advanced)

Share your device's compute power:

```dart
// Access via developer console
final computeNetwork = ref.read(computeNetworkProvider);

await computeNetwork.join(
  nodeId: 'my-node',
  maxConcurrentTasks: 2,
  allowedDevices: [DeviceType.cpu],
);
```

## Configuration

### Adding Custom Relays (NOSTR)

Edit `lib/core/nostr/nostr_relay.dart`:

```dart
static List<NostrRelay> getDefaults() {
  return [
    // ... existing relays
    NostrRelay(
      url: 'wss://your-custom-relay.com',
      name: 'My Relay',
    ),
  ];
}
```

### Adjusting Blockchain Difficulty

Edit `lib/features/hub/providers/hub_providers.dart`:

```dart
HubManager()
  : blockchain = Blockchain(difficulty: 2), // Lower = faster mining
```

### Customizing HDP Settings

Edit `lib/core/hdp/hdp_manager.dart`:

```dart
HDPManager({
  this.totalShards = 10,      // Total fragments
  int? thresholdShards,       // Minimum needed (default: 70%)
})
```

## Development

### Project Structure

```
lib/
├── core/              # Core business logic
├── features/          # UI features
├── shared/            # Shared utilities
└── main.dart          # Entry point
```

### Adding a New App Type

1. **Add enum value** in `lib/core/tokens/app_token.dart`:
```dart
enum AppTokenType {
  // ... existing types
  linkedin,  // Add new type
}
```

2. **Create template** in `lib/shared/models/app_templates.dart`:
```dart
static AppTokenTemplate linkedinTemplate = AppTokenTemplate(
  name: 'LinkedIn',
  type: AppTokenType.linkedin,
  url: 'https://linkedin.com',
  // ... configuration
);
```

3. **Add to getAll()** list in `AppTemplates`

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Desktop
flutter build linux --release
```

## Troubleshooting

### Flutter not found
```bash
# Add Flutter to PATH (Linux/macOS)
export PATH="$PATH:`pwd`/flutter/bin"

# Verify
flutter doctor
```

### Dependencies not installing
```bash
flutter clean
flutter pub get
```

### Build runner errors
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### WebView not working
Ensure you're on a supported platform:
- ✅ Android
- ✅ iOS
- ⚠️ Desktop (limited)
- ❌ Web (not supported)

## Next Steps

1. Read the full [README.md](README.md) for detailed features
2. Check [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
3. Explore the code to understand the implementation
4. Contribute improvements via Pull Requests!

## Support

- **Issues**: Open on GitHub
- **Questions**: Check existing issues or create new one
- **Features**: Request via GitHub issues

Happy hacking! 🚀
