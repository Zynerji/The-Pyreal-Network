# Pyreal Hub - The Social Compute Network

A revolutionary hybrid NOSTR client/relay/private blockchain hub application built with Flutter. Pyreal Hub integrates decentralized social media, secure token-based authentication, holographic data partitioning, and distributed OpenCL compute sharing.

## 🌟 Features

### Core Capabilities

- **🔐 Token-Based App Management**: Mint AppTokens for each application/website with encrypted credentials
- **📱 Multi-App Hub Interface**: Load multiple apps in tabs like a browser with a custom workbar
- **🌐 NOSTR Client & Relay**: Full-featured decentralized social media integration
- **⛓️ Private Blockchain**: Immutable token minting and usage tracking
- **🔮 Holographic Data Partitioning (HDP)**: Advanced distributed data storage with 30% fault tolerance
- **⚡ OpenCL Compute Sharing**: Distributed GPU/CPU compute across the network
- **🎨 Beautiful UI**: Modern dark theme with smooth animations

### Architecture Highlights

#### Holographic Data Partitioning (HDP)

HDP treats data as a hologram, encoding it into fragments where each contains a linear combination of the entire dataset:

- **Encoding**: Uses orthogonal matrices and FFT-like transformations
- **Distribution**: Fragments spread across nodes via consistent hashing
- **Reconstruction**: Any 70% of fragments can rebuild the complete data
- **Resilience**: Tolerates up to 30% node failures while maintaining integrity
- **Security**: Individual fragments reveal minimal information

#### Token System

**AppTokens**: Represent applications loaded into tabs
- Minted with user credentials (encrypted via HDP)
- Stored on the private blockchain
- Support for NOSTR, social media, email, browsers, and custom apps

**WidgeTokens**: Bottom workbar widgets that switch between app categories
- Social, Email, Browser, Apps
- Customizable with icons and colors

## ⚡ Synergies - The Power of Integration

Pyreal Hub's true power comes from how all components work together:

### 1. **NOSTR + Blockchain = Social Proof**
Every NOSTR event can be verified on the blockchain, creating immutable social proof and reputation scores.

### 2. **HDP + GPU Compute = 50-100x Faster Encoding**
GPU acceleration for holographic data partitioning provides real-time data protection with massive performance gains.

### 3. **Token Minting + Compute = Earn While You Share**
Users earn PYREAL tokens by contributing GPU/CPU/NPU power to the network, creating a self-sustaining economy.

### 4. **Blockchain Identity = Web3 SSO**
Single blockchain-based identity works across all apps with zero-knowledge proofs for selective disclosure.

### 5. **NOSTR Relay + Rewards = Decentralized Infrastructure**
Earn tokens for hosting NOSTR relays, creating incentive for robust, distributed infrastructure.

### 6. **Extended Device Support**
Beyond CPU/GPU, Pyreal Hub leverages:
- **NPU** (Neural Processing Units) for AI/ML tasks
- **DSP** (Digital Signal Processors) for audio/signal processing
- **ISP** (Image Signal Processors) for camera/image processing
- **Video Encoders** for hardware-accelerated transcoding

### 7. **Decentralized App Marketplace**
Apps tokenized on blockchain, traded trustlessly, with reputation-based recommendations from NOSTR.

### 8. **Federated ML Training**
Distribute machine learning across mobile NPUs for privacy-preserving, battery-efficient AI.

### 9. **HDP + Blockchain = Cryptographically Verified Fragments**
Fragment hashes on blockchain create tamper-proof distributed storage with complete audit trail.

### 10. **Cross-App Social Graph**
Your identity, reputation, and social connections work across all apps in the hub.

## 🚀 Getting Started

### Prerequisites

```bash
flutter --version  # Flutter 3.0.0 or higher
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/The-Pyreal-Network.git
cd The-Pyreal-Network
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📱 Usage

### Creating AppTokens

1. Select a WidgeToken from the bottom workbar (e.g., Social, Email)
2. Click the `+` button in the top tab bar
3. Fill in the app details and credentials
4. Click "Mint Token" to securely store your credentials

### Switching Between Apps

- **Tabs**: Swipe or tap tabs at the top to switch between apps
- **Workbar**: Tap WidgeTokens at the bottom to change app categories

### Pre-made Templates

Pyreal Hub includes templates for:
- NOSTR Social Feed (default)
- Twitter/X
- Instagram
- TikTok
- Facebook
- YouTube
- Email
- Web Browser

## 🏗️ Architecture

```
lib/
├── core/
│   ├── blockchain/        # Private blockchain implementation
│   │   ├── block.dart
│   │   └── blockchain.dart
│   ├── hdp/              # Holographic Data Partitioning
│   │   └── hdp_manager.dart
│   ├── nostr/            # NOSTR client/relay
│   │   ├── nostr_client.dart
│   │   ├── nostr_event.dart
│   │   └── nostr_relay.dart
│   ├── tokens/           # Token system
│   │   ├── app_token.dart
│   │   └── widge_token.dart
│   └── compute/          # OpenCL compute sharing
│       ├── opencl_manager.dart
│       └── compute_network.dart
├── features/
│   ├── hub/              # Main hub interface
│   │   ├── hub_screen.dart
│   │   ├── providers/
│   │   └── widgets/
│   └── social/           # NOSTR social feed
│       └── nostr_feed_view.dart
├── shared/
│   ├── models/
│   │   └── app_templates.dart
│   └── services/
│       └── token_minting_service.dart
└── main.dart
```

## 🔐 Security

### Credential Encryption

All credentials are encrypted using SHA-256 based XOR encryption and fragmented using HDP before storage:

1. **Encryption**: Credentials encrypted with user-specific key
2. **Fragmentation**: Encrypted data split into holographic fragments
3. **Distribution**: Fragments distributed across storage nodes
4. **Blockchain**: Token minting recorded on private blockchain

### Data Integrity

- All blockchain blocks are cryptographically hashed
- Proof-of-work mining with configurable difficulty
- HDP fragments include checksums for verification
- Token usage tracked immutably on blockchain

## 🌐 NOSTR Integration

### Default Relays

- `wss://relay.damus.io`
- `wss://nos.lol`
- `wss://relay.snort.social`
- `wss://relay.nostr.band`

### Supported Event Types

- Text notes (kind 1)
- Metadata (kind 0)
- Contacts (kind 3)
- Reactions (kind 7)
- And more...

## ⚡ OpenCL Compute Sharing

Share your device's GPU/CPU resources with the network:

```dart
// Join compute network
await computeNetwork.join(
  nodeId: 'my-node',
  maxConcurrentTasks: 4,
  allowedDevices: [DeviceType.gpu, DeviceType.cpu],
);

// Submit distributed task
final task = await computeNetwork.submitDistributedTask(
  kernelSource: myKernelCode,
  inputs: {'data': myData},
  preferredDevice: DeviceType.gpu,
);
```

### Features

- Automatic device detection (CPU, GPU, accelerators)
- Task distribution across network nodes
- Load balancing based on device capabilities
- Fault tolerance with task reassignment

## 📊 Blockchain Statistics

Access blockchain stats programmatically:

```dart
final stats = blockchain.getStats();
print('Total blocks: ${stats['totalBlocks']}');
print('Token mints: ${stats['tokenMints']}');
print('Valid chain: ${stats['isValid']}');
```

## 🛠️ Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Desktop
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌟 Acknowledgments

- NOSTR protocol developers
- Flutter and Dart teams
- OpenCL community
- Blockchain pioneers

## 📞 Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ using Flutter and the power of decentralization**
