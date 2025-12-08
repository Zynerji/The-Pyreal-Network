import 'dart:async';
import 'dart:math';
import '../blockchain/blockchain.dart';
import '../orchestration/conductor.dart';
import '../compute/device_type.dart';
import 'package:logger/logger.dart';

/// Supported game types
enum GameType {
  minecraft,
  rust,
  ark,
  counterStrike2,
  valheim,
  palworld,
  terraria,
  sevenDaysToDie,
  conanExiles,
  projectZomboid,
}

/// Server configuration presets
enum ServerPreset {
  small,      // 10-20 players
  medium,     // 20-50 players
  large,      // 50-100 players
  massive,    // 100+ players
}

/// Geographic regions for server placement
enum GameServerRegion {
  usEast,
  usWest,
  usCentral,
  euWest,
  euEast,
  asiaPacific,
  southAmerica,
  oceania,
}

/// Server requirements based on game and preset
class ServerRequirements {
  final int ramGB;
  final int cpuCores;
  final int storageGB;
  final double bandwidthMbps;
  final int maxPlayers;
  final Map<String, dynamic> gameSpecificConfig;

  const ServerRequirements({
    required this.ramGB,
    required this.cpuCores,
    required this.storageGB,
    required this.bandwidthMbps,
    required this.maxPlayers,
    required this.gameSpecificConfig,
  });

  static ServerRequirements forGame(GameType game, ServerPreset preset) {
    switch (game) {
      case GameType.minecraft:
        switch (preset) {
          case ServerPreset.small:
            return ServerRequirements(
              ramGB: 2,
              cpuCores: 2,
              storageGB: 10,
              bandwidthMbps: 10,
              maxPlayers: 20,
              gameSpecificConfig: {'version': '1.20', 'difficulty': 'normal'},
            );
          case ServerPreset.medium:
            return ServerRequirements(
              ramGB: 4,
              cpuCores: 4,
              storageGB: 20,
              bandwidthMbps: 20,
              maxPlayers: 50,
              gameSpecificConfig: {'version': '1.20', 'difficulty': 'normal'},
            );
          case ServerPreset.large:
            return ServerRequirements(
              ramGB: 8,
              cpuCores: 6,
              storageGB: 40,
              bandwidthMbps: 50,
              maxPlayers: 100,
              gameSpecificConfig: {'version': '1.20', 'difficulty': 'hard'},
            );
          case ServerPreset.massive:
            return ServerRequirements(
              ramGB: 16,
              cpuCores: 8,
              storageGB: 100,
              bandwidthMbps: 100,
              maxPlayers: 200,
              gameSpecificConfig: {'version': '1.20', 'difficulty': 'hard'},
            );
        }

      case GameType.rust:
        switch (preset) {
          case ServerPreset.small:
            return ServerRequirements(
              ramGB: 4,
              cpuCores: 4,
              storageGB: 15,
              bandwidthMbps: 20,
              maxPlayers: 50,
              gameSpecificConfig: {'worldSize': 3000, 'seed': 12345},
            );
          case ServerPreset.medium:
            return ServerRequirements(
              ramGB: 8,
              cpuCores: 6,
              storageGB: 30,
              bandwidthMbps: 40,
              maxPlayers: 100,
              gameSpecificConfig: {'worldSize': 4000, 'seed': 12345},
            );
          case ServerPreset.large:
            return ServerRequirements(
              ramGB: 16,
              cpuCores: 8,
              storageGB: 60,
              bandwidthMbps: 80,
              maxPlayers: 200,
              gameSpecificConfig: {'worldSize': 5000, 'seed': 12345},
            );
          default:
            return ServerRequirements(
              ramGB: 8,
              cpuCores: 6,
              storageGB: 30,
              bandwidthMbps: 40,
              maxPlayers: 100,
              gameSpecificConfig: {'worldSize': 4000, 'seed': 12345},
            );
        }

      case GameType.ark:
        return ServerRequirements(
          ramGB: 8,
          cpuCores: 4,
          storageGB: 50,
          bandwidthMbps: 30,
          maxPlayers: preset == ServerPreset.small ? 20 : 70,
          gameSpecificConfig: {'map': 'TheIsland', 'taming': 2.0},
        );

      case GameType.valheim:
        return ServerRequirements(
          ramGB: 4,
          cpuCores: 2,
          storageGB: 10,
          bandwidthMbps: 15,
          maxPlayers: preset == ServerPreset.small ? 10 : 20,
          gameSpecificConfig: {'world': 'Valhalla', 'password': 'secret'},
        );

      default:
        return ServerRequirements(
          ramGB: 4,
          cpuCores: 2,
          storageGB: 20,
          bandwidthMbps: 20,
          maxPlayers: 50,
          gameSpecificConfig: {},
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'ramGB': ramGB,
        'cpuCores': cpuCores,
        'storageGB': storageGB,
        'bandwidthMbps': bandwidthMbps,
        'maxPlayers': maxPlayers,
        'gameSpecificConfig': gameSpecificConfig,
      };
}

/// Game server instance
class GameServer {
  final String serverId;
  final String ownerId;
  final String hostNodeId;
  final GameType gameType;
  final ServerPreset preset;
  final ServerRequirements requirements;
  final GameServerRegion region;
  final String serverName;
  final bool isPublic;
  final DateTime createdAt;

  int currentPlayers;
  bool isRunning;
  double uptimePercentage;
  double totalEarnedPyreal;
  Map<String, dynamic> serverConfig;

  GameServer({
    required this.serverId,
    required this.ownerId,
    required this.hostNodeId,
    required this.gameType,
    required this.preset,
    required this.requirements,
    required this.region,
    required this.serverName,
    this.isPublic = true,
    required this.createdAt,
    this.currentPlayers = 0,
    this.isRunning = false,
    this.uptimePercentage = 99.0,
    this.totalEarnedPyreal = 0.0,
    Map<String, dynamic>? serverConfig,
  }) : serverConfig = serverConfig ?? {};

  double get playerUtilization => requirements.maxPlayers > 0 ? currentPlayers / requirements.maxPlayers : 0.0;

  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'ownerId': ownerId,
        'hostNodeId': hostNodeId,
        'gameType': gameType.name,
        'preset': preset.name,
        'requirements': requirements.toJson(),
        'region': region.name,
        'serverName': serverName,
        'isPublic': isPublic,
        'currentPlayers': currentPlayers,
        'maxPlayers': requirements.maxPlayers,
        'playerUtilization': playerUtilization,
        'isRunning': isRunning,
        'uptimePercentage': uptimePercentage,
        'totalEarnedPyreal': totalEarnedPyreal,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Host node capable of running game servers
class GameHostNode {
  final String nodeId;
  final GameServerRegion region;
  final DeviceType deviceType;
  final int totalRamGB;
  final int totalCpuCores;
  final int totalStorageGB;
  final double bandwidthMbps;

  int availableRamGB;
  int availableCpuCores;
  int availableStorageGB;
  Set<String> hostedServers;
  double totalEarnedPyreal;
  double uptimePercentage;

  GameHostNode({
    required this.nodeId,
    required this.region,
    required this.deviceType,
    required this.totalRamGB,
    required this.totalCpuCores,
    required this.totalStorageGB,
    required this.bandwidthMbps,
    int? availableRamGB,
    int? availableCpuCores,
    int? availableStorageGB,
    Set<String>? hostedServers,
    this.totalEarnedPyreal = 0.0,
    this.uptimePercentage = 99.0,
  })  : availableRamGB = availableRamGB ?? totalRamGB,
        availableCpuCores = availableCpuCores ?? totalCpuCores,
        availableStorageGB = availableStorageGB ?? totalStorageGB,
        hostedServers = hostedServers ?? {};

  bool canHostServer(ServerRequirements requirements) {
    return availableRamGB >= requirements.ramGB &&
        availableCpuCores >= requirements.cpuCores &&
        availableStorageGB >= requirements.storageGB &&
        bandwidthMbps >= requirements.bandwidthMbps;
  }

  void allocateResources(ServerRequirements requirements) {
    availableRamGB -= requirements.ramGB;
    availableCpuCores -= requirements.cpuCores;
    availableStorageGB -= requirements.storageGB;
  }

  void releaseResources(ServerRequirements requirements) {
    availableRamGB += requirements.ramGB;
    availableCpuCores += requirements.cpuCores;
    availableStorageGB += requirements.storageGB;
  }

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'region': region.name,
        'deviceType': deviceType.name,
        'totalRamGB': totalRamGB,
        'availableRamGB': availableRamGB,
        'totalCpuCores': totalCpuCores,
        'availableCpuCores': availableCpuCores,
        'totalStorageGB': totalStorageGB,
        'availableStorageGB': availableStorageGB,
        'bandwidthMbps': bandwidthMbps,
        'hostedServers': hostedServers.toList(),
        'totalEarnedPyreal': totalEarnedPyreal,
        'uptimePercentage': uptimePercentage,
      };
}

/// Player session tracking
class PlayerSession {
  final String sessionId;
  final String serverId;
  final String playerId;
  final DateTime startTime;
  DateTime? endTime;
  double costPyreal;

  PlayerSession({
    required this.sessionId,
    required this.serverId,
    required this.playerId,
    required this.startTime,
    this.endTime,
    this.costPyreal = 0.0,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'serverId': serverId,
        'playerId': playerId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': duration.inMinutes,
        'costPyreal': costPyreal,
      };
}

/// Distributed Game Server Hosting Network
class GameServerHost {
  final Blockchain blockchain;
  final Conductor conductor;
  final Logger _logger = Logger();

  final Map<String, GameHostNode> _hostNodes = {};
  final Map<String, GameServer> _servers = {};
  final Map<String, List<PlayerSession>> _playerSessions = {}; // serverId -> sessions

  // Pricing: 2-3 ₱ per hour per player slot
  static const double _pricePerPlayerHour = 2.5;

  GameServerHost({
    required this.blockchain,
    required this.conductor,
  });

  /// Register a node as game server host
  Future<GameHostNode> registerHostNode({
    required String nodeId,
    required GameServerRegion region,
    required DeviceType deviceType,
    required int ramGB,
    required int cpuCores,
    required int storageGB,
    required double bandwidthMbps,
  }) async {
    _logger.i('Registering game host node: $nodeId in ${region.name}');

    // Verify minimum requirements
    if (ramGB < 4 || cpuCores < 2 || storageGB < 10) {
      throw Exception('Node does not meet minimum requirements for game hosting');
    }

    final node = GameHostNode(
      nodeId: nodeId,
      region: region,
      deviceType: deviceType,
      totalRamGB: ramGB,
      totalCpuCores: cpuCores,
      totalStorageGB: storageGB,
      bandwidthMbps: bandwidthMbps,
    );

    _hostNodes[nodeId] = node;

    _logger.i('Game host node registered: $nodeId with $ramGB GB RAM');

    return node;
  }

  /// Deploy a game server
  Future<GameServer> deployServer({
    required String ownerId,
    required GameType gameType,
    required ServerPreset preset,
    required String serverName,
    List<GameServerRegion>? preferredRegions,
    bool isPublic = true,
    Map<String, dynamic>? customConfig,
  }) async {
    _logger.i('Deploying $gameType server: $serverName ($preset)');

    final requirements = ServerRequirements.forGame(gameType, preset);

    // Find optimal host node using Conductor
    final optimalNode = await _findOptimalHostNode(
      requirements: requirements,
      preferredRegions: preferredRegions,
      ownerId: ownerId,
    );

    if (optimalNode == null) {
      throw Exception('No available host nodes for requirements: ${requirements.toJson()}');
    }

    // Calculate monthly cost
    final hourlyCost = requirements.maxPlayers * _pricePerPlayerHour;
    final monthlyCost = hourlyCost * 730; // Average hours per month

    _logger.i('Server cost: $hourlyCost ₱/hour, $monthlyCost ₱/month (at full capacity)');

    // Verify owner can afford at least 24 hours
    final balance = await blockchain.getBalance(ownerId);
    final minimumDeposit = hourlyCost * 24;

    if (balance < minimumDeposit) {
      throw Exception('Insufficient balance: $balance ₱ < $minimumDeposit ₱ (24h minimum)');
    }

    final serverId = _generateServerId();

    final server = GameServer(
      serverId: serverId,
      ownerId: ownerId,
      hostNodeId: optimalNode.nodeId,
      gameType: gameType,
      preset: preset,
      requirements: requirements,
      region: optimalNode.region,
      serverName: serverName,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      serverConfig: customConfig ?? requirements.gameSpecificConfig,
    );

    // Allocate resources on host node
    optimalNode.allocateResources(requirements);
    optimalNode.hostedServers.add(serverId);

    _servers[serverId] = server;
    _playerSessions[serverId] = [];

    // Start server
    await _startServer(server);

    _logger.i('Server deployed: $serverId on ${optimalNode.nodeId} in ${optimalNode.region.name}');

    return server;
  }

  /// Find optimal host node for server
  Future<GameHostNode?> _findOptimalHostNode({
    required ServerRequirements requirements,
    List<GameServerRegion>? preferredRegions,
    required String ownerId,
  }) async {
    _logger.i('Finding optimal host node for ${requirements.maxPlayers} player server');

    // Use Conductor to analyze player locations if provided
    // For now, use simple region preference and resource availability

    final candidates = _hostNodes.values
        .where((node) => node.canHostServer(requirements))
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    // Prioritize by preferred regions
    if (preferredRegions != null && preferredRegions.isNotEmpty) {
      final regionalCandidates = candidates.where((n) => preferredRegions.contains(n.region)).toList();

      if (regionalCandidates.isNotEmpty) {
        candidates.clear();
        candidates.addAll(regionalCandidates);
      }
    }

    // Sort by resource availability and uptime
    candidates.sort((a, b) {
      final scoreA = (a.availableRamGB / a.totalRamGB) * a.uptimePercentage;
      final scoreB = (b.availableRamGB / b.totalRamGB) * b.uptimePercentage;
      return scoreB.compareTo(scoreA);
    });

    final selected = candidates.first;
    _logger.i('Selected host: ${selected.nodeId} in ${selected.region.name} (${selected.availableRamGB}GB RAM available)');

    return selected;
  }

  /// Start a game server
  Future<void> _startServer(GameServer server) async {
    _logger.i('Starting server: ${server.serverName}');

    // In production, this would:
    // 1. Provision Docker container on host node
    // 2. Configure game server files
    // 3. Open necessary ports
    // 4. Start game server process

    server.isRunning = true;

    _logger.i('Server started: ${server.serverId}');
  }

  /// Player joins server
  Future<PlayerSession> joinServer({
    required String serverId,
    required String playerId,
  }) async {
    final server = _servers[serverId];
    if (server == null) {
      throw Exception('Server not found: $serverId');
    }

    if (!server.isRunning) {
      throw Exception('Server is not running');
    }

    if (server.currentPlayers >= server.requirements.maxPlayers) {
      throw Exception('Server full: ${server.currentPlayers}/${server.requirements.maxPlayers}');
    }

    _logger.i('Player $playerId joining ${server.serverName}');

    final sessionId = _generateSessionId();
    final session = PlayerSession(
      sessionId: sessionId,
      serverId: serverId,
      playerId: playerId,
      startTime: DateTime.now(),
    );

    _playerSessions[serverId]!.add(session);
    server.currentPlayers++;

    _logger.i('Player joined: ${server.currentPlayers}/${server.requirements.maxPlayers}');

    // Start billing timer
    _startBillingForSession(session, server);

    return session;
  }

  /// Start billing for player session
  void _startBillingForSession(PlayerSession session, GameServer server) {
    // In production, this would track actual time and bill hourly
    // For now, simulate billing on session end
    _logger.d('Billing started for session ${session.sessionId}');
  }

  /// Player leaves server
  Future<void> leaveServer({
    required String serverId,
    required String playerId,
  }) async {
    final server = _servers[serverId];
    if (server == null) {
      throw Exception('Server not found: $serverId');
    }

    final sessions = _playerSessions[serverId]!;
    final session = sessions.firstWhere(
      (s) => s.playerId == playerId && s.endTime == null,
      orElse: () => throw Exception('Active session not found for player $playerId'),
    );

    session.endTime = DateTime.now();
    server.currentPlayers--;

    // Calculate cost
    final hours = session.duration.inMinutes / 60.0;
    session.costPyreal = hours * _pricePerPlayerHour;

    // Process payment
    await _processSessionPayment(session, server);

    _logger.i('Player left: ${server.currentPlayers}/${server.requirements.maxPlayers} (session cost: ${session.costPyreal.toStringAsFixed(2)} ₱)');
  }

  /// Process payment for player session
  Future<void> _processSessionPayment(PlayerSession session, GameServer server) async {
    final cost = session.costPyreal;

    // Revenue split: 70% host, 20% treasury, 10% server owner
    final hostShare = cost * 0.70;
    final treasuryShare = cost * 0.20;
    final ownerShare = cost * 0.10;

    final hostNode = _hostNodes[server.hostNodeId]!;

    // Payment from player to host
    await blockchain.transferPyreal(
      fromUserId: session.playerId,
      toUserId: hostNode.nodeId,
      amount: hostShare,
      memo: 'Game session: ${server.serverName}',
    );

    hostNode.totalEarnedPyreal += hostShare;
    server.totalEarnedPyreal += cost;

    // Treasury share
    await blockchain.transferPyreal(
      fromUserId: session.playerId,
      toUserId: 'treasury',
      amount: treasuryShare,
      memo: 'Game hosting treasury',
    );

    // Server owner share
    await blockchain.transferPyreal(
      fromUserId: session.playerId,
      toUserId: server.ownerId,
      amount: ownerShare,
      memo: 'Server owner commission: ${server.serverName}',
    );

    _logger.i('Session payment processed: $cost ₱ (host: $hostShare ₱)');
  }

  /// Shutdown and remove server
  Future<void> shutdownServer(String serverId) async {
    final server = _servers[serverId];
    if (server == null) {
      throw Exception('Server not found: $serverId');
    }

    _logger.i('Shutting down server: ${server.serverName}');

    // Kick all active players
    final activeSessions = _playerSessions[serverId]!.where((s) => s.endTime == null).toList();

    for (final session in activeSessions) {
      await leaveServer(serverId: serverId, playerId: session.playerId);
    }

    server.isRunning = false;

    // Release resources on host node
    final hostNode = _hostNodes[server.hostNodeId]!;
    hostNode.releaseResources(server.requirements);
    hostNode.hostedServers.remove(serverId);

    _logger.i('Server shut down: $serverId');
  }

  /// Get server list
  List<GameServer> getServerList({
    GameType? gameType,
    GameServerRegion? region,
    bool? hasSlots,
  }) {
    var servers = _servers.values.where((s) => s.isRunning && s.isPublic).toList();

    if (gameType != null) {
      servers = servers.where((s) => s.gameType == gameType).toList();
    }

    if (region != null) {
      servers = servers.where((s) => s.region == region).toList();
    }

    if (hasSlots == true) {
      servers = servers.where((s) => s.currentPlayers < s.requirements.maxPlayers).toList();
    }

    // Sort by player count (most popular first)
    servers.sort((a, b) => b.currentPlayers.compareTo(a.currentPlayers));

    return servers;
  }

  /// Get host node statistics
  Future<Map<String, dynamic>> getHostNodeStats(String nodeId) async {
    final node = _hostNodes[nodeId];
    if (node == null) {
      throw Exception('Host node not found: $nodeId');
    }

    final hostedServersList = node.hostedServers.map((id) => _servers[id]!).toList();
    final totalPlayers = hostedServersList.map((s) => s.currentPlayers).fold(0, (a, b) => a + b);

    // Calculate potential monthly earnings
    final totalSlots = hostedServersList.map((s) => s.requirements.maxPlayers).fold(0, (a, b) => a + b);
    final maxMonthlyEarnings = totalSlots * _pricePerPlayerHour * 730 * 0.70; // 70% host share

    return {
      'nodeId': nodeId,
      'region': node.region.name,
      'hostedServers': node.hostedServers.length,
      'totalPlayers': totalPlayers,
      'totalSlots': totalSlots,
      'utilization': node.totalRamGB > 0 ? (node.totalRamGB - node.availableRamGB) / node.totalRamGB : 0.0,
      'totalEarnedPyreal': node.totalEarnedPyreal,
      'maxMonthlyEarnings': maxMonthlyEarnings,
      'uptimePercentage': node.uptimePercentage,
    };
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    final totalServers = _servers.length;
    final runningServers = _servers.values.where((s) => s.isRunning).length;
    final totalPlayers = _servers.values.map((s) => s.currentPlayers).fold(0, (a, b) => a + b);
    final totalSlots = _servers.values.map((s) => s.requirements.maxPlayers).fold(0, (a, b) => a + b);

    final serversByGame = <GameType, int>{};
    for (final server in _servers.values) {
      serversByGame[server.gameType] = (serversByGame[server.gameType] ?? 0) + 1;
    }

    final nodesByRegion = <GameServerRegion, int>{};
    for (final node in _hostNodes.values) {
      nodesByRegion[node.region] = (nodesByRegion[node.region] ?? 0) + 1;
    }

    final totalRevenue = _hostNodes.values.map((n) => n.totalEarnedPyreal).fold(0.0, (a, b) => a + b);

    return {
      'totalHostNodes': _hostNodes.length,
      'totalServers': totalServers,
      'runningServers': runningServers,
      'totalPlayers': totalPlayers,
      'totalSlots': totalSlots,
      'utilization': totalSlots > 0 ? totalPlayers / totalSlots : 0.0,
      'serversByGame': serversByGame.map((k, v) => MapEntry(k.name, v)),
      'nodesByRegion': nodesByRegion.map((k, v) => MapEntry(k.name, v)),
      'totalRevenue': totalRevenue,
    };
  }

  // Helper methods

  String _generateServerId() {
    return 'server_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
