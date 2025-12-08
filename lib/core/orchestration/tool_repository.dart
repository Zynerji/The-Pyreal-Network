import 'package:logger/logger.dart';
import '../blockchain/blockchain.dart';
import '../hdp/hdp_manager.dart';

/// Tool Repository - Rent, build, save, and execute AI tools
/// Enables the Conductor to dynamically create and monetize tools
class ToolRepository {
  final Blockchain blockchain;
  final HDPManager hdpManager;
  final Logger _logger = Logger();

  // Tool storage
  final Map<String, Tool> _tools = {};
  final Map<String, ToolRental> _activeRentals = {};
  final Map<String, List<ToolExecution>> _executionHistory = {};

  // Revenue tracking
  double _totalToolRevenue = 0.0;
  int _totalToolExecutions = 0;
  int _totalToolsRented = 0;

  ToolRepository({
    required this.blockchain,
    required this.hdpManager,
  });

  // =========================================================================
  // TOOL CREATION - Conductor can build custom tools
  // =========================================================================

  /// Build a new tool using LLM code generation
  /// The Conductor analyzes requirements and generates executable code
  Future<Tool> buildTool({
    required String name,
    required String description,
    required ToolCategory category,
    required Map<String, dynamic> requirements,
    required String creatorUserId,
  }) async {
    _logger.i('🔨 Building tool: $name');

    // Generate tool code using Conductor's LLM
    final toolCode = await _generateToolCode(
      name: name,
      description: description,
      category: category,
      requirements: requirements,
    );

    // Create tool metadata
    final tool = Tool(
      id: 'tool_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      code: toolCode,
      creatorUserId: creatorUserId,
      version: '1.0.0',
      pricePerExecution: _calculateToolPrice(category, requirements),
      createdAt: DateTime.now(),
      parameters: requirements['parameters'] as List<ToolParameter>? ?? [],
      returnType: requirements['returnType'] as String? ?? 'dynamic',
    );

    // Store tool in HDP for distributed access
    final toolData = tool.toJson();
    final fragmentId = await hdpManager.encodeData(toolData.toString().codeUnits);

    // Register on blockchain
    blockchain.addBlock({
      'type': 'tool_created',
      'toolId': tool.id,
      'name': tool.name,
      'creator': creatorUserId,
      'fragmentId': fragmentId,
      'price': tool.pricePerExecution,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _tools[tool.id] = tool;
    _logger.i('✅ Tool built: ${tool.name} (${tool.id})');

    return tool;
  }

  /// Generate executable code for a tool using LLM
  Future<String> _generateToolCode({
    required String name,
    required String description,
    required ToolCategory category,
    required Map<String, dynamic> requirements,
  }) async {
    // In production, this would use Conductor's LLM to generate code
    // For now, we'll generate template code based on category

    final buffer = StringBuffer();
    buffer.writeln('// Auto-generated tool: $name');
    buffer.writeln('// Description: $description');
    buffer.writeln('// Category: ${category.name}');
    buffer.writeln();
    buffer.writeln('Future<dynamic> execute(Map<String, dynamic> params) async {');

    switch (category) {
      case ToolCategory.dataProcessing:
        buffer.writeln('  // Data processing logic');
        buffer.writeln('  final input = params["input"];');
        buffer.writeln('  final processed = await processData(input);');
        buffer.writeln('  return processed;');
        break;
      case ToolCategory.aiInference:
        buffer.writeln('  // AI inference logic');
        buffer.writeln('  final prompt = params["prompt"];');
        buffer.writeln('  final result = await runInference(prompt);');
        buffer.writeln('  return result;');
        break;
      case ToolCategory.blockchain:
        buffer.writeln('  // Blockchain interaction logic');
        buffer.writeln('  final transaction = params["transaction"];');
        buffer.writeln('  final txHash = await submitTransaction(transaction);');
        buffer.writeln('  return txHash;');
        break;
      case ToolCategory.api:
        buffer.writeln('  // API call logic');
        buffer.writeln('  final endpoint = params["endpoint"];');
        buffer.writeln('  final response = await callAPI(endpoint);');
        buffer.writeln('  return response;');
        break;
      case ToolCategory.financial:
        buffer.writeln('  // Financial computation logic');
        buffer.writeln('  final data = params["marketData"];');
        buffer.writeln('  final analysis = await analyzeMarket(data);');
        buffer.writeln('  return analysis;');
        break;
      case ToolCategory.security:
        buffer.writeln('  // Security analysis logic');
        buffer.writeln('  final target = params["target"];');
        buffer.writeln('  final report = await scanSecurity(target);');
        buffer.writeln('  return report;');
        break;
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Calculate price based on tool complexity and category
  double _calculateToolPrice(ToolCategory category, Map<String, dynamic> requirements) {
    // Base prices per execution
    const basePrices = {
      ToolCategory.dataProcessing: 0.1,
      ToolCategory.aiInference: 1.0,
      ToolCategory.blockchain: 0.5,
      ToolCategory.api: 0.2,
      ToolCategory.financial: 2.0,
      ToolCategory.security: 1.5,
    };

    double price = basePrices[category] ?? 0.5;

    // Adjust based on complexity
    final complexity = requirements['complexity'] as String? ?? 'medium';
    switch (complexity) {
      case 'low':
        price *= 0.5;
        break;
      case 'medium':
        // No adjustment
        break;
      case 'high':
        price *= 2.0;
        break;
      case 'extreme':
        price *= 5.0;
        break;
    }

    return price;
  }

  // =========================================================================
  // TOOL RENTAL - Users can rent tools for ongoing use
  // =========================================================================

  /// Rent a tool for a specified duration
  Future<ToolRental> rentTool({
    required String toolId,
    required String renterUserId,
    required Duration rentalDuration,
  }) async {
    final tool = _tools[toolId];
    if (tool == null) {
      throw Exception('Tool not found: $toolId');
    }

    // Calculate rental cost
    final hoursRented = rentalDuration.inHours.clamp(1, 8760); // Max 1 year
    final rentalCost = tool.pricePerExecution * hoursRented * 10; // 10x bulk discount

    _logger.i('🔑 Renting tool: ${tool.name} for $hoursRented hours (${rentalCost.toStringAsFixed(2)} ₱)');

    final rental = ToolRental(
      id: 'rental_${DateTime.now().millisecondsSinceEpoch}',
      toolId: toolId,
      renterUserId: renterUserId,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(rentalDuration),
      cost: rentalCost,
      executionsRemaining: hoursRented * 100, // 100 executions per hour
    );

    _activeRentals[rental.id] = rental;
    _totalToolsRented++;
    _totalToolRevenue += rentalCost;

    // Record rental on blockchain
    blockchain.addBlock({
      'type': 'tool_rental',
      'rentalId': rental.id,
      'toolId': toolId,
      'renter': renterUserId,
      'duration': hoursRented,
      'cost': rentalCost,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Distribute revenue
    _distributeToolRevenue(
      toolId: toolId,
      amount: rentalCost,
      isRental: true,
    );

    return rental;
  }

  // =========================================================================
  // TOOL EXECUTION - Execute rented or pay-per-use tools
  // =========================================================================

  /// Execute a tool with given parameters
  Future<ToolExecutionResult> executeTool({
    required String toolId,
    required String userId,
    required Map<String, dynamic> parameters,
    String? rentalId,
  }) async {
    final tool = _tools[toolId];
    if (tool == null) {
      throw Exception('Tool not found: $toolId');
    }

    // Check if user has active rental
    ToolRental? rental;
    if (rentalId != null) {
      rental = _activeRentals[rentalId];
      if (rental == null || rental.isExpired() || rental.executionsRemaining <= 0) {
        throw Exception('Rental expired or no executions remaining');
      }
    }

    _logger.d('⚙️ Executing tool: ${tool.name}');

    // Execute tool code (sandboxed)
    final startTime = DateTime.now();
    dynamic result;
    bool success = true;
    String? error;

    try {
      result = await _executeToolCode(tool.code, parameters);
    } catch (e) {
      success = false;
      error = e.toString();
      _logger.e('Tool execution failed: $error');
    }

    final duration = DateTime.now().difference(startTime);

    // Record execution
    final execution = ToolExecution(
      toolId: toolId,
      userId: userId,
      timestamp: DateTime.now(),
      duration: duration,
      success: success,
      parameters: parameters,
      result: result,
      error: error,
      rentalId: rentalId,
    );

    _executionHistory[toolId] = (_executionHistory[toolId] ?? [])..add(execution);
    _totalToolExecutions++;

    // Charge user (if not using rental)
    if (rental != null) {
      rental.executionsRemaining--;
      _logger.d('Rental executions remaining: ${rental.executionsRemaining}');
    } else {
      // Pay-per-execution
      _distributeToolRevenue(
        toolId: toolId,
        amount: tool.pricePerExecution,
        isRental: false,
      );
      _totalToolRevenue += tool.pricePerExecution;
    }

    return ToolExecutionResult(
      success: success,
      result: result,
      error: error,
      duration: duration,
      cost: rental != null ? 0.0 : tool.pricePerExecution,
    );
  }

  /// Execute tool code in sandboxed environment
  Future<dynamic> _executeToolCode(String code, Map<String, dynamic> params) async {
    // In production, this would:
    // 1. Run code in isolated sandbox (Dart isolate or WASM)
    // 2. Apply resource limits (CPU, memory, network)
    // 3. Monitor for security violations
    // 4. Return results or throw exceptions

    // Simulate execution
    await Future.delayed(Duration(milliseconds: 100));

    // Return mock result based on parameters
    return {
      'status': 'success',
      'data': params,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // =========================================================================
  // REVENUE DISTRIBUTION
  // =========================================================================

  /// Distribute tool revenue to creator, network, and treasury
  void _distributeToolRevenue({
    required String toolId,
    required double amount,
    required bool isRental,
  }) {
    final tool = _tools[toolId]!;

    // Revenue split
    final creatorShare = amount * 0.70; // 70% to tool creator
    final treasuryShare = amount * 0.20; // 20% to network treasury
    final burned = amount * 0.10; // 10% burned

    _logger.d('💰 Tool revenue distribution: ${amount.toStringAsFixed(2)} ₱');
    _logger.d('   Creator (${tool.creatorUserId}): ${creatorShare.toStringAsFixed(2)} ₱');
    _logger.d('   Treasury: ${treasuryShare.toStringAsFixed(2)} ₱');
    _logger.d('   Burned: ${burned.toStringAsFixed(2)} ₱');

    // Record on blockchain
    blockchain.addBlock({
      'type': 'tool_revenue',
      'toolId': toolId,
      'amount': amount,
      'creatorShare': creatorShare,
      'treasuryShare': treasuryShare,
      'burned': burned,
      'isRental': isRental,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // =========================================================================
  // MARKETPLACE & DISCOVERY
  // =========================================================================

  /// Get all available tools in marketplace
  List<Tool> getMarketplaceTools({ToolCategory? category}) {
    if (category == null) {
      return _tools.values.toList()
        ..sort((a, b) => b.totalExecutions.compareTo(a.totalExecutions));
    }

    return _tools.values
        .where((tool) => tool.category == category)
        .toList()
      ..sort((a, b) => b.totalExecutions.compareTo(a.totalExecutions));
  }

  /// Search tools by keyword
  List<Tool> searchTools(String query) {
    final lowerQuery = query.toLowerCase();
    return _tools.values.where((tool) {
      return tool.name.toLowerCase().contains(lowerQuery) ||
          tool.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get tool statistics
  Map<String, dynamic> getToolStats(String toolId) {
    final tool = _tools[toolId];
    if (tool == null) return {};

    final executions = _executionHistory[toolId] ?? [];
    final successfulExecutions = executions.where((e) => e.success).length;
    final avgDuration = executions.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: executions
                    .map((e) => e.duration.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                executions.length,
          );

    return {
      'toolId': toolId,
      'name': tool.name,
      'totalExecutions': executions.length,
      'successRate': executions.isEmpty ? 0.0 : successfulExecutions / executions.length,
      'averageDuration': avgDuration.inMilliseconds,
      'totalRevenue': _calculateToolTotalRevenue(toolId),
      'activeRentals': _activeRentals.values.where((r) => r.toolId == toolId && !r.isExpired()).length,
    };
  }

  double _calculateToolTotalRevenue(String toolId) {
    // Calculate from execution history and rentals
    double total = 0.0;

    // Execution revenue
    final executions = _executionHistory[toolId] ?? [];
    final tool = _tools[toolId]!;
    total += executions.where((e) => e.rentalId == null).length * tool.pricePerExecution;

    // Rental revenue
    final rentals = _activeRentals.values.where((r) => r.toolId == toolId);
    total += rentals.fold<double>(0.0, (sum, r) => sum + r.cost);

    return total;
  }

  /// Get repository statistics
  Map<String, dynamic> getRepositoryStats() {
    return {
      'totalTools': _tools.length,
      'totalExecutions': _totalToolExecutions,
      'totalRentals': _totalToolsRented,
      'totalRevenue': _totalToolRevenue,
      'toolsByCategory': _getToolCountByCategory(),
      'topTools': _getTopTools(5),
    };
  }

  Map<String, int> _getToolCountByCategory() {
    final counts = <String, int>{};
    for (final tool in _tools.values) {
      counts[tool.category.name] = (counts[tool.category.name] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> _getTopTools(int count) {
    final sortedTools = _tools.values.toList()
      ..sort((a, b) => b.totalExecutions.compareTo(a.totalExecutions));

    return sortedTools.take(count).map((tool) => {
      'id': tool.id,
      'name': tool.name,
      'executions': tool.totalExecutions,
      'revenue': _calculateToolTotalRevenue(tool.id),
    }).toList();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

enum ToolCategory {
  dataProcessing,
  aiInference,
  blockchain,
  api,
  financial,
  security,
}

class Tool {
  final String id;
  final String name;
  final String description;
  final ToolCategory category;
  final String code;
  final String creatorUserId;
  final String version;
  final double pricePerExecution;
  final DateTime createdAt;
  final List<ToolParameter> parameters;
  final String returnType;
  int totalExecutions = 0;

  Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.code,
    required this.creatorUserId,
    required this.version,
    required this.pricePerExecution,
    required this.createdAt,
    required this.parameters,
    required this.returnType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'code': code,
        'creatorUserId': creatorUserId,
        'version': version,
        'pricePerExecution': pricePerExecution,
        'createdAt': createdAt.toIso8601String(),
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'returnType': returnType,
        'totalExecutions': totalExecutions,
      };
}

class ToolParameter {
  final String name;
  final String type;
  final bool required;
  final String? description;
  final dynamic defaultValue;

  ToolParameter({
    required this.name,
    required this.type,
    required this.required,
    this.description,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'required': required,
        'description': description,
        'defaultValue': defaultValue,
      };
}

class ToolRental {
  final String id;
  final String toolId;
  final String renterUserId;
  final DateTime startTime;
  final DateTime endTime;
  final double cost;
  int executionsRemaining;

  ToolRental({
    required this.id,
    required this.toolId,
    required this.renterUserId,
    required this.startTime,
    required this.endTime,
    required this.cost,
    required this.executionsRemaining,
  });

  bool isExpired() => DateTime.now().isAfter(endTime);
}

class ToolExecution {
  final String toolId;
  final String userId;
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final Map<String, dynamic> parameters;
  final dynamic result;
  final String? error;
  final String? rentalId;

  ToolExecution({
    required this.toolId,
    required this.userId,
    required this.timestamp,
    required this.duration,
    required this.success,
    required this.parameters,
    this.result,
    this.error,
    this.rentalId,
  });
}

class ToolExecutionResult {
  final bool success;
  final dynamic result;
  final String? error;
  final Duration duration;
  final double cost;

  ToolExecutionResult({
    required this.success,
    this.result,
    this.error,
    required this.duration,
    required this.cost,
  });
}
