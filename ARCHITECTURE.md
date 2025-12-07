# Pyreal Hub Architecture

## Overview

Pyreal Hub is a sophisticated multi-paradigm application that combines:
- Decentralized social networking (NOSTR)
- Private blockchain for token management
- Holographic data partitioning for distributed storage
- OpenCL-based distributed computing
- Modern Flutter UI with state management

## Core Components

### 1. Token System

#### AppToken
Represents an application that can be loaded into a tab.

**Properties:**
- `id`: Unique identifier
- `name`: Display name
- `type`: AppTokenType enum (nostrSocial, email, browser, etc.)
- `url`: Application URL or endpoint
- `credentials`: Encrypted user credentials
- `hdpFragments`: List of HDP fragment IDs for credential storage
- `mintedAt`: Timestamp of token creation
- `userId`: Owner of the token
- `metadata`: Additional configuration

**Token Types:**
- NOSTR Social
- Email
- Social Media (Twitter, Instagram, TikTok, Facebook, YouTube)
- Browser
- Custom

#### WidgeToken
Represents a widget button on the bottom workbar.

**Properties:**
- `id`: Unique identifier
- `name`: Display name
- `icon`: Flutter IconData
- `targetType`: AppTokenType to display when selected
- `color`: Theme color
- `position`: Order in workbar
- `isDefault`: Whether it's a system default

**Default WidgeTokens:**
1. Social (purple) - Shows NOSTR and social media apps
2. Email (blue) - Shows email clients
3. Browser (green) - Shows web browsers
4. Apps (orange) - Shows custom applications

### 2. Holographic Data Partitioning (HDP)

HDP provides distributed, fault-tolerant data storage by treating data as a hologram.

#### How It Works

**Encoding Phase:**
```
1. Generate orthogonal matrix (Gram-Schmidt process)
2. Apply FFT-like transformation to data
3. Create fragments with redundancy (XOR operations)
4. Add Reed-Solomon error correction
5. Calculate checksums for each fragment
```

**Distribution Phase:**
```
1. Use consistent hashing to assign fragments to nodes
2. Distribute fragments across network
3. Store fragment metadata in token
```

**Reconstruction Phase:**
```
1. Collect threshold number of fragments (default: 70%)
2. Verify checksums
3. Apply inverse transformation
4. Reconstruct original data
```

#### Key Properties

- **Threshold**: 70% of fragments needed for reconstruction
- **Fault Tolerance**: Survives 30% node failures
- **Security**: Single fragment reveals minimal information
- **Scalability**: Fragments can be distributed across unlimited nodes

#### HDPManager API

```dart
// Encode data into fragments
List<HDPFragment> fragments = await hdpManager.encodeData(data);

// Distribute fragments
Map<String, List<HDPFragment>> distribution =
  hdpManager.distributeFragments(fragments, nodeIds);

// Reconstruct data
Uint8List originalData = await hdpManager.reconstructData(fragments);
```

### 3. Private Blockchain

A proof-of-work blockchain for immutable token tracking.

#### Block Structure

```dart
class Block {
  int index;           // Block number in chain
  DateTime timestamp;  // When block was created
  Map data;           // Block payload (token mint/usage)
  String previousHash; // Hash of previous block
  String hash;        // This block's hash
  int nonce;          // Proof of work nonce
}
```

#### Mining Process

```
1. Create block with transaction data
2. Set difficulty (number of leading zeros required)
3. Increment nonce until hash meets difficulty
4. Verify block against previous block
5. Add to chain if valid
```

#### Transaction Types

**Token Mint:**
```json
{
  "type": "token_mint",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "tokenId": "uuid",
    "name": "Twitter",
    "type": "twitter",
    "userId": "user123"
  }
}
```

**Token Usage:**
```json
{
  "type": "token_usage",
  "timestamp": "2024-01-01T01:00:00Z",
  "tokenId": "uuid",
  "data": {
    "action": "login",
    "success": true
  }
}
```

#### Blockchain API

```dart
// Create blockchain
Blockchain blockchain = Blockchain(difficulty: 4);

// Mint token
blockchain.mintToken(tokenData);

// Record usage
blockchain.useToken(tokenId, usageData);

// Validate chain
bool valid = blockchain.isValid();

// Get statistics
Map<String, dynamic> stats = blockchain.getStats();
```

### 4. NOSTR Integration

Full NOSTR protocol implementation for decentralized social media.

#### Components

**NostrClient:**
- WebSocket connections to multiple relays
- Event subscription and publishing
- Automatic reconnection
- Event stream management

**NostrEvent:**
- NIP-01 compliant events
- Event ID calculation (SHA-256)
- Signature verification
- Tag parsing

**NostrRelay:**
- Relay configuration
- Read/write permissions
- Metadata storage

#### Event Flow

```
1. Connect to relays → WebSocket connections
2. Subscribe to filters → REQ message
3. Receive events → EVENT messages
4. Publish events → EVENT message
5. Handle responses → NOTICE, EOSE messages
```

#### Supported Event Kinds

- `0`: Metadata (profiles)
- `1`: Text notes (posts)
- `2`: Recommend relay
- `3`: Contacts (following)
- `4`: Encrypted direct messages
- `5`: Deletion
- `6`: Repost
- `7`: Reaction (like)
- `40-42`: Channel operations

### 5. OpenCL Compute Sharing

Distributed GPU/CPU compute across the network.

#### Architecture

**OpenCLManager:**
- Device detection and initialization
- Local task execution
- Device capability queries

**ComputeNetwork:**
- Network node management
- Task distribution
- Load balancing

#### Compute Task Lifecycle

```
1. Submit task with kernel source
2. Select optimal node/device
3. Distribute to node
4. Execute on device
5. Return results
6. Update statistics
```

#### Device Selection Algorithm

```
1. Filter available nodes (not at max capacity)
2. If preferred device type specified:
   - Find nodes with matching device
3. Otherwise:
   - Select node with least current tasks
4. If multiple matches:
   - Prefer GPU over CPU
   - Prefer more compute units
```

#### ComputeNetwork API

```dart
// Join network
await computeNetwork.join(
  nodeId: 'node1',
  maxConcurrentTasks: 4,
  allowedDevices: [DeviceType.gpu],
);

// Submit task
ComputeTask task = await computeNetwork.submitDistributedTask(
  kernelSource: kernelCode,
  inputs: {'data': input},
  preferredDevice: DeviceType.gpu,
);

// Get statistics
Map<String, dynamic> stats = computeNetwork.getNetworkStats();
```

### 6. UI Architecture

#### Screen Hierarchy

```
HubScreen (Main)
├── AppTabBar (Top)
│   ├── TabItem (for each AppToken)
│   └── AddButton
├── AppCanvas (Center)
│   ├── NostrFeedView (for NOSTR tokens)
│   └── WebViewWidget (for other tokens)
└── Workbar (Bottom)
    └── WorkbarButton (for each WidgeToken)
```

#### State Management (Riverpod)

**Providers:**

```dart
// Main hub state
hubManagerProvider: StateNotifierProvider<HubManager, HubState>

// Derived providers
appTokensProvider: List<AppToken>
widgeTokensProvider: List<WidgeToken>
activeWidgeTokenProvider: WidgeToken
currentTabProvider: int

// Core services
blockchainProvider: Blockchain
nostrClientProvider: NostrClient
hdpManagerProvider: HDPManager
```

**State Flow:**

```
User Action
  ↓
Provider Update
  ↓
State Change
  ↓
UI Rebuild
```

## Data Flow

### Token Minting Flow

```
1. User enters credentials
   ↓
2. TokenMintingService.mintToken()
   ↓
3. Encrypt credentials (XOR + SHA-256)
   ↓
4. Fragment with HDP
   ↓
5. Create AppToken with fragment IDs
   ↓
6. Record on blockchain
   ↓
7. Update UI state
```

### App Loading Flow

```
1. User selects tab
   ↓
2. Update currentTabProvider
   ↓
3. AppCanvas receives new token
   ↓
4. If NOSTR: Load NostrFeedView
   If web: Load WebViewWidget
   ↓
5. Initialize app with credentials
   ↓
6. Record usage on blockchain
```

### NOSTR Event Flow

```
1. NostrClient connects to relays
   ↓
2. Subscribe to event kinds
   ↓
3. Relay sends EVENT messages
   ↓
4. Parse NostrEvent
   ↓
5. Add to event stream
   ↓
6. NostrFeedView rebuilds with new events
```

## Security Model

### Credential Storage

```
Plain Credentials
  ↓ [Encrypt: XOR + SHA-256]
Encrypted Credentials
  ↓ [Fragment: HDP]
Distributed Fragments
  ↓ [Store: Multiple nodes]
Fragment IDs in Token
  ↓ [Record: Blockchain]
Immutable Record
```

### Security Features

1. **Encryption**: XOR cipher with SHA-256 key derivation
2. **Fragmentation**: HDP splits data across multiple fragments
3. **Distribution**: Fragments stored on different nodes
4. **Checksums**: Each fragment has SHA-256 checksum
5. **Blockchain**: Immutable audit log
6. **Proof of Work**: Prevents chain tampering

### Threat Model

**Protected Against:**
- ✅ Single node compromise (HDP tolerance)
- ✅ Blockchain tampering (proof of work)
- ✅ Fragment corruption (checksums)
- ✅ Credential theft (encryption + fragmentation)

**Not Protected Against:**
- ❌ User device compromise
- ❌ Weak user passwords
- ❌ Man-in-the-middle (use HTTPS/WSS)

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**: Tabs load content only when selected
2. **WebView Reuse**: WebViewController cached per token
3. **Event Streaming**: NOSTR events buffered (max 100)
4. **Fragment Caching**: HDP fragments cached locally
5. **Blockchain Pruning**: Can archive old blocks

### Resource Usage

**Memory:**
- ~50MB base app
- ~10MB per WebView
- ~1MB per 100 NOSTR events
- ~5MB blockchain (1000 blocks)

**Network:**
- NOSTR: 1-5 KB/s (active feed)
- WebView: Variable (depends on loaded app)
- Compute: 10-100 KB/task

**Compute:**
- Blockchain mining: 1-2 seconds/block (difficulty 4)
- HDP encoding: ~100ms/MB
- NOSTR event parsing: ~1ms/event

## Extensibility

### Adding New AppToken Types

1. Add enum value to `AppTokenType`
2. Create template in `AppTemplates`
3. Add icon mapping in `AppTabBar`
4. Implement custom view if needed

### Adding New Compute Kernels

1. Write OpenCL kernel source
2. Submit via `OpenCLManager.submitTask()`
3. Handle results in callback

### Adding New NOSTR Event Kinds

1. Add constant to `NostrEventKind`
2. Update event parsing in `NostrFeedView`
3. Create custom card widget if needed

## Future Enhancements

1. **P2P Networking**: Direct node-to-node communication
2. **Smart Contracts**: Programmable blockchain logic
3. **Multi-Device Sync**: Cross-device token synchronization
4. **Advanced Crypto**: Schnorr signatures for NOSTR
5. **GPU Acceleration**: WebGPU for faster HDP operations
6. **Offline Mode**: Local-first with sync when online

## Conclusion

Pyreal Hub combines cutting-edge technologies to create a unique, secure, and performant hub application. The architecture is designed for extensibility, security, and user privacy while providing a seamless experience across multiple applications and platforms.
