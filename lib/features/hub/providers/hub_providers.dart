import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens/app_token.dart';
import '../../../core/tokens/widge_token.dart';
import '../../../core/blockchain/blockchain.dart';
import '../../../core/nostr/nostr_client.dart';
import '../../../core/hdp/hdp_manager.dart';
import 'package:uuid/uuid.dart';

/// Hub manager for coordinating all app functionality
class HubManager extends StateNotifier<HubState> {
  final Blockchain blockchain;
  final NostrClient nostrClient;
  final HDPManager hdpManager;

  HubManager()
      : blockchain = Blockchain(),
        nostrClient = NostrClient(),
        hdpManager = HDPManager(),
        super(HubState.initial());

  Future<void> initialize() async {
    // Initialize default NOSTR social feed token
    final defaultNostrToken = AppToken(
      id: 'default_nostr',
      name: 'NOSTR Feed',
      type: AppTokenType.nostrSocial,
      url: '',
      credentials: {},
      iconPath: 'assets/images/nostr.png',
      mintedAt: DateTime.now(),
      userId: 'default_user',
      isDefault: true,
    );

    state = state.copyWith(
      appTokens: [defaultNostrToken],
    );
  }

  Future<void> mintAppToken({
    required String name,
    required AppTokenType type,
    required String url,
    required Map<String, dynamic> credentials,
    required String userId,
  }) async {
    final token = AppToken(
      id: const Uuid().v4(),
      name: name,
      type: type,
      url: url,
      credentials: credentials,
      iconPath: 'assets/images/${type.name}.png',
      mintedAt: DateTime.now(),
      userId: userId,
    );

    // Store in blockchain
    blockchain.mintToken({
      'tokenId': token.id,
      'name': token.name,
      'type': token.type.name,
      'userId': userId,
    });

    // Add to state
    state = state.copyWith(
      appTokens: [...state.appTokens, token],
    );
  }

  void removeAppToken(String tokenId) {
    state = state.copyWith(
      appTokens: state.appTokens.where((t) => t.id != tokenId).toList(),
    );
  }

  Future<void> connectToNostr() async {
    await nostrClient.connectAll();
  }

  void disposeNostr() {
    nostrClient.dispose();
  }

  @override
  void dispose() {
    nostrClient.dispose();
    super.dispose();
  }
}

/// Hub state model
class HubState {
  final List<AppToken> appTokens;
  final List<WidgeToken> widgeTokens;
  final bool isLoading;
  final String? error;

  HubState({
    required this.appTokens,
    required this.widgeTokens,
    this.isLoading = false,
    this.error,
  });

  factory HubState.initial() {
    return HubState(
      appTokens: [],
      widgeTokens: WidgeToken.getDefaults(),
    );
  }

  HubState copyWith({
    List<AppToken>? appTokens,
    List<WidgeToken>? widgeTokens,
    bool? isLoading,
    String? error,
  }) {
    return HubState(
      appTokens: appTokens ?? this.appTokens,
      widgeTokens: widgeTokens ?? this.widgeTokens,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Providers
final hubManagerProvider = StateNotifierProvider<HubManager, HubState>((ref) {
  return HubManager();
});

final appTokensProvider = Provider<List<AppToken>>((ref) {
  return ref.watch(hubManagerProvider).appTokens;
});

final widgeTokensProvider = Provider<List<WidgeToken>>((ref) {
  return ref.watch(hubManagerProvider).widgeTokens;
});

final activeWidgeTokenProvider = StateProvider<WidgeToken>((ref) {
  final widgeTokens = ref.watch(widgeTokensProvider);
  return widgeTokens.first;
});

final currentTabProvider = StateProvider<int>((ref) {
  return 0;
});

final blockchainProvider = Provider<Blockchain>((ref) {
  return ref.watch(hubManagerProvider.notifier).blockchain;
});

final nostrClientProvider = Provider<NostrClient>((ref) {
  return ref.watch(hubManagerProvider.notifier).nostrClient;
});

final hdpManagerProvider = Provider<HDPManager>((ref) {
  return ref.watch(hubManagerProvider.notifier).hdpManager;
});
