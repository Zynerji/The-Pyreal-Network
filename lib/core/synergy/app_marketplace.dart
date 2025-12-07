import '../blockchain/blockchain.dart';
import '../tokens/app_token.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

/// Decentralized app marketplace using blockchain tokens
/// Synergy: Token system + Blockchain = Trustless app distribution
class AppMarketplace {
  final Blockchain blockchain;
  final Logger _logger = Logger();

  AppMarketplace({required this.blockchain});

  /// List app on marketplace
  Future<MarketplaceListing> listApp({
    required String developerId,
    required String appName,
    required String description,
    required AppTokenType appType,
    required double price,
    required Map<String, dynamic> metadata,
  }) async {
    final listingId = const Uuid().v4();

    final listing = MarketplaceListing(
      id: listingId,
      developerId: developerId,
      appName: appName,
      description: description,
      appType: appType,
      price: price,
      listedAt: DateTime.now(),
      metadata: metadata,
      downloads: 0,
      rating: 0.0,
      reviews: [],
    );

    // Record on blockchain
    blockchain.addBlock({
      'type': 'app_listing',
      'listingId': listingId,
      'developerId': developerId,
      'appName': appName,
      'appType': appType.name,
      'price': price,
      'listedAt': listing.listedAt.toIso8601String(),
    });

    _logger.i('Listed app on marketplace: $appName ($price tokens)');

    return listing;
  }

  /// Purchase app from marketplace
  Future<AppToken> purchaseApp({
    required String userId,
    required String listingId,
    required double paymentAmount,
  }) async {
    // Verify listing exists
    final listing = await _getListing(listingId);
    if (listing == null) {
      throw Exception('Listing not found');
    }

    // Verify payment
    if (paymentAmount < listing.price) {
      throw Exception('Insufficient payment');
    }

    // Record purchase on blockchain
    blockchain.addBlock({
      'type': 'app_purchase',
      'listingId': listingId,
      'userId': userId,
      'developerId': listing.developerId,
      'price': listing.price,
      'purchasedAt': DateTime.now().toIso8601String(),
    });

    // Mint app token for user
    final appToken = AppToken(
      id: const Uuid().v4(),
      name: listing.appName,
      type: listing.appType,
      url: listing.metadata['url'] ?? '',
      credentials: {},
      iconPath: listing.metadata['iconPath'] ?? 'assets/images/app.png',
      mintedAt: DateTime.now(),
      userId: userId,
      metadata: {
        'purchasedFrom': 'marketplace',
        'listingId': listingId,
        'pricePaid': paymentAmount,
      },
    );

    _logger.i('Purchased app: ${listing.appName} for $userId');

    return appToken;
  }

  /// Rate and review app
  Future<void> reviewApp({
    required String userId,
    required String listingId,
    required double rating,
    required String review,
  }) async {
    // Verify user purchased the app
    final hasPurchased = await _verifyPurchase(userId, listingId);
    if (!hasPurchased) {
      throw Exception('Must purchase app before reviewing');
    }

    // Record review on blockchain
    blockchain.addBlock({
      'type': 'app_review',
      'listingId': listingId,
      'userId': userId,
      'rating': rating,
      'review': review,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    _logger.i('Recorded review for listing $listingId: $rating stars');
  }

  /// Get app listing details
  Future<MarketplaceListing?> _getListing(String listingId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'app_listing' && data['listingId'] == listingId);

    if (blocks.isEmpty) return null;

    final blockData = blocks.first.data;

    // Get stats
    final downloads = await _getDownloadCount(listingId);
    final rating = await _getAverageRating(listingId);

    return MarketplaceListing(
      id: listingId,
      developerId: blockData['developerId'],
      appName: blockData['appName'],
      description: '',
      appType: AppTokenType.values.firstWhere(
        (t) => t.name == blockData['appType'],
        orElse: () => AppTokenType.custom,
      ),
      price: blockData['price'],
      listedAt: DateTime.parse(blockData['listedAt']),
      metadata: {},
      downloads: downloads,
      rating: rating,
      reviews: [],
    );
  }

  /// Verify user purchased app
  Future<bool> _verifyPurchase(String userId, String listingId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'app_purchase' &&
        data['userId'] == userId &&
        data['listingId'] == listingId);

    return blocks.isNotEmpty;
  }

  /// Get download count for listing
  Future<int> _getDownloadCount(String listingId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'app_purchase' && data['listingId'] == listingId);

    return blocks.length;
  }

  /// Get average rating for listing
  Future<double> _getAverageRating(String listingId) async {
    final blocks = blockchain.searchBlocks((data) =>
        data['type'] == 'app_review' && data['listingId'] == listingId);

    if (blocks.isEmpty) return 0.0;

    final totalRating = blocks.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['rating'] as num).toDouble(),
    );

    return totalRating / blocks.length;
  }

  /// Get trending apps based on recent purchases
  Future<List<Map<String, dynamic>>> getTrendingApps({int limit = 10}) async {
    final recentPurchases = blockchain
        .searchBlocks((data) => data['type'] == 'app_purchase')
        .take(100)
        .toList();

    // Count purchases per listing
    final purchaseCounts = <String, int>{};
    for (final block in recentPurchases) {
      final listingId = block.data['listingId'] as String;
      purchaseCounts[listingId] = (purchaseCounts[listingId] ?? 0) + 1;
    }

    // Sort by purchase count
    final trending = purchaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return trending.take(limit).map((entry) => {
      'listingId': entry.key,
      'recentPurchases': entry.value,
    }).toList();
  }

  /// Get developer earnings
  Future<double> getDeveloperEarnings(String developerId) async {
    final sales = blockchain.searchBlocks((data) =>
        data['type'] == 'app_purchase' && data['developerId'] == developerId);

    return sales.fold<double>(
      0.0,
      (sum, block) => sum + (block.data['price'] as num).toDouble(),
    );
  }
}

/// App marketplace listing
class MarketplaceListing {
  final String id;
  final String developerId;
  final String appName;
  final String description;
  final AppTokenType appType;
  final double price;
  final DateTime listedAt;
  final Map<String, dynamic> metadata;
  final int downloads;
  final double rating;
  final List<String> reviews;

  MarketplaceListing({
    required this.id,
    required this.developerId,
    required this.appName,
    required this.description,
    required this.appType,
    required this.price,
    required this.listedAt,
    required this.metadata,
    required this.downloads,
    required this.rating,
    required this.reviews,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'developerId': developerId,
    'appName': appName,
    'description': description,
    'appType': appType.name,
    'price': price,
    'listedAt': listedAt.toIso8601String(),
    'metadata': metadata,
    'downloads': downloads,
    'rating': rating,
    'reviews': reviews,
  };
}
