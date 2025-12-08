import 'dart:async';
import 'dart:math';
import '../blockchain/blockchain.dart';
import '../orchestration/conductor.dart';
import 'package:logger/logger.dart';

/// Reputation tiers for credit scoring
enum ReputationTier {
  bronze,    // 0-999
  silver,    // 1,000-4,999
  gold,      // 5,000-9,999
  platinum,  // 10,000+
}

/// Loan status
enum LoanStatus {
  pending,
  active,
  repaying,
  completed,
  defaulted,
  liquidated,
}

/// Collateral types
enum CollateralType {
  pyreal,
  bitcoin,
  ethereum,
  stablecoins,
  nftAssets,
  computeCredits,
}

/// User credit profile
class CreditProfile {
  final String userId;
  final int reputationScore;
  final double computeHoursContributed;
  final double pyrealStaked;
  final int successfulLoansCompleted;
  final int defaultedLoans;
  final double totalBorrowed;
  final double totalRepaid;

  const CreditProfile({
    required this.userId,
    required this.reputationScore,
    required this.computeHoursContributed,
    required this.pyrealStaked,
    this.successfulLoansCompleted = 0,
    this.defaultedLoans = 0,
    this.totalBorrowed = 0.0,
    this.totalRepaid = 0.0,
  });

  ReputationTier get tier {
    if (reputationScore >= 10000) return ReputationTier.platinum;
    if (reputationScore >= 5000) return ReputationTier.gold;
    if (reputationScore >= 1000) return ReputationTier.silver;
    return ReputationTier.bronze;
  }

  double get creditScore {
    // Composite score out of 100
    final reputationComponent = min(reputationScore / 150, 100.0); // Max 100 for 15k+ reputation
    final computeComponent = min(computeHoursContributed / 20, 100.0); // Max 100 for 2000+ hours
    final stakeComponent = min(pyrealStaked / 100, 100.0); // Max 100 for 10k+ staked
    final historyComponent = successfulLoansCompleted * 2.0 - defaultedLoans * 10.0;

    return ((reputationComponent * 0.40) +
            (computeComponent * 0.30) +
            (stakeComponent * 0.20) +
            (historyComponent * 0.10))
        .clamp(0.0, 100.0);
  }

  String get creditGrade {
    final score = creditScore;
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'A-';
    if (score >= 75) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 65) return 'B-';
    if (score >= 60) return 'C+';
    if (score >= 55) return 'C';
    if (score >= 50) return 'C-';
    return 'D';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'reputationScore': reputationScore,
        'tier': tier.name,
        'creditScore': creditScore,
        'creditGrade': creditGrade,
        'computeHoursContributed': computeHoursContributed,
        'pyrealStaked': pyrealStaked,
        'successfulLoans': successfulLoansCompleted,
        'defaultedLoans': defaultedLoans,
        'totalBorrowed': totalBorrowed,
        'totalRepaid': totalRepaid,
      };
}

/// Loan terms and conditions
class LoanTerms {
  final double principalAmount;
  final double interestRateAPY;
  final Duration loanDuration;
  final double collateralAmount;
  final CollateralType collateralType;
  final double loanToValueRatio; // LTV
  final double liquidationThreshold;
  final DateTime? earlyRepaymentDate;

  const LoanTerms({
    required this.principalAmount,
    required this.interestRateAPY,
    required this.loanDuration,
    required this.collateralAmount,
    required this.collateralType,
    required this.loanToValueRatio,
    required this.liquidationThreshold,
    this.earlyRepaymentDate,
  });

  double get totalRepaymentAmount {
    final annualInterest = principalAmount * (interestRateAPY / 100);
    final durationYears = loanDuration.inDays / 365;
    return principalAmount + (annualInterest * durationYears);
  }

  Map<String, dynamic> toJson() => {
        'principalAmount': principalAmount,
        'interestRateAPY': interestRateAPY,
        'loanDuration': loanDuration.inDays,
        'collateralAmount': collateralAmount,
        'collateralType': collateralType.name,
        'loanToValueRatio': loanToValueRatio,
        'liquidationThreshold': liquidationThreshold,
        'totalRepaymentAmount': totalRepaymentAmount,
        'earlyRepaymentDate': earlyRepaymentDate?.toIso8601String(),
      };
}

/// Active loan
class Loan {
  final String loanId;
  final String borrowerId;
  final String? lenderId; // Can be pool or individual
  final LoanTerms terms;
  final DateTime startDate;
  final DateTime dueDate;
  final String smartContractId;

  LoanStatus status;
  double amountRepaid;
  DateTime? completedDate;
  List<LoanPayment> paymentHistory;

  Loan({
    required this.loanId,
    required this.borrowerId,
    this.lenderId,
    required this.terms,
    required this.startDate,
    required this.dueDate,
    required this.smartContractId,
    this.status = LoanStatus.active,
    this.amountRepaid = 0.0,
    this.completedDate,
    List<LoanPayment>? paymentHistory,
  }) : paymentHistory = paymentHistory ?? [];

  double get remainingBalance => terms.totalRepaymentAmount - amountRepaid;
  double get percentageRepaid =>
      (amountRepaid / terms.totalRepaymentAmount * 100).clamp(0.0, 100.0);

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == LoanStatus.active;

  Map<String, dynamic> toJson() => {
        'loanId': loanId,
        'borrowerId': borrowerId,
        'lenderId': lenderId,
        'terms': terms.toJson(),
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'amountRepaid': amountRepaid,
        'remainingBalance': remainingBalance,
        'percentageRepaid': percentageRepaid,
        'isOverdue': isOverdue,
        'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      };
}

/// Loan payment record
class LoanPayment {
  final String paymentId;
  final String loanId;
  final double amount;
  final DateTime paymentDate;
  final String? memo;

  const LoanPayment({
    required this.paymentId,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'loanId': loanId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'memo': memo,
      };
}

/// Lending pool for passive income
class LendingPool {
  final String poolId;
  final Map<String, double> lenders; // userId -> amount staked
  final double totalPoolSize;
  final double totalLoaned;
  final double totalEarned;
  final double currentAPY;

  const LendingPool({
    required this.poolId,
    required this.lenders,
    this.totalPoolSize = 0.0,
    this.totalLoaned = 0.0,
    this.totalEarned = 0.0,
    this.currentAPY = 8.0,
  });

  Map<String, dynamic> toJson() => {
        'poolId': poolId,
        'lenders': lenders,
        'totalPoolSize': totalPoolSize,
        'totalLoaned': totalLoaned,
        'totalEarned': totalEarned,
        'utilizationRate': totalPoolSize > 0 ? totalLoaned / totalPoolSize : 0.0,
        'currentAPY': currentAPY,
      };
}

/// Reputation-based lending protocol
class LendingProtocol {
  final Blockchain blockchain;
  final Conductor conductor;
  final Logger _logger = Logger();

  final Map<String, CreditProfile> _creditProfiles = {};
  final Map<String, Loan> _loans = {};
  final Map<String, List<String>> _userLoans = {}; // userId -> loanIds
  final LendingPool _mainPool;

  // Interest rate ranges by tier
  static const Map<ReputationTier, List<double>> _interestRateRanges = {
    ReputationTier.platinum: [6.0, 8.0],   // 6-8% APY
    ReputationTier.gold: [9.0, 12.0],      // 9-12% APY
    ReputationTier.silver: [13.0, 18.0],   // 13-18% APY
    ReputationTier.bronze: [19.0, 25.0],   // 19-25% APY
  };

  // Loan-to-value ratios by tier
  static const Map<ReputationTier, double> _ltvRatios = {
    ReputationTier.platinum: 0.80,  // 80% LTV
    ReputationTier.gold: 0.60,      // 60% LTV
    ReputationTier.silver: 0.40,    // 40% LTV
    ReputationTier.bronze: 0.20,    // 20% LTV
  };

  LendingProtocol({
    required this.blockchain,
    required this.conductor,
  }) : _mainPool = LendingPool(
          poolId: 'main_pool',
          lenders: {},
        );

  /// Get or create credit profile for user
  Future<CreditProfile> getCreditProfile(String userId) async {
    if (_creditProfiles.containsKey(userId)) {
      return _creditProfiles[userId]!;
    }

    // Fetch reputation from Conductor
    final reputation = await conductor.getUserReputation(userId);

    // Fetch compute contribution history
    final computeStats = await conductor.getComputeStats(userId);
    final computeHours = computeStats['totalHours'] as double? ?? 0.0;

    // Fetch staked PYREAL
    final staked = await blockchain.getStakedBalance(userId);

    // Get loan history
    final loanHistory = _userLoans[userId] ?? [];
    final successfulLoans = loanHistory
        .where((id) => _loans[id]?.status == LoanStatus.completed)
        .length;
    final defaultedLoans = loanHistory
        .where((id) => _loans[id]?.status == LoanStatus.defaulted)
        .length;

    final profile = CreditProfile(
      userId: userId,
      reputationScore: reputation,
      computeHoursContributed: computeHours,
      pyrealStaked: staked,
      successfulLoansCompleted: successfulLoans,
      defaultedLoans: defaultedLoans,
    );

    _creditProfiles[userId] = profile;

    _logger.i('Credit profile created: $userId - ${profile.creditGrade} (${profile.creditScore.toStringAsFixed(1)}/100)');

    return profile;
  }

  /// Request a loan
  Future<Loan> requestLoan({
    required String borrowerId,
    required double amount,
    required Duration duration,
    required CollateralType collateralType,
    required double collateralAmount,
  }) async {
    _logger.i('Loan request: $borrowerId requesting $amount ₱ for ${duration.inDays} days');

    // Get borrower's credit profile
    final profile = await getCreditProfile(borrowerId);

    // Calculate interest rate based on credit score
    final interestRate = _calculateInterestRate(profile);

    // Calculate maximum LTV based on tier
    final maxLTV = _ltvRatios[profile.tier]!;
    final actualLTV = amount / collateralAmount;

    if (actualLTV > maxLTV) {
      throw Exception('LTV too high: $actualLTV > $maxLTV (max for ${profile.tier.name})');
    }

    // Verify collateral availability
    final balance = await blockchain.getBalance(borrowerId);
    if (collateralType == CollateralType.pyreal && balance < collateralAmount) {
      throw Exception('Insufficient collateral: $balance ₱ < $collateralAmount ₱');
    }

    // Check if pool has sufficient liquidity
    final poolLiquidity = _mainPool.totalPoolSize - _mainPool.totalLoaned;
    if (poolLiquidity < amount) {
      throw Exception('Insufficient pool liquidity: $poolLiquidity ₱ < $amount ₱');
    }

    final loanId = _generateLoanId();

    final terms = LoanTerms(
      principalAmount: amount,
      interestRateAPY: interestRate,
      loanDuration: duration,
      collateralAmount: collateralAmount,
      collateralType: collateralType,
      loanToValueRatio: actualLTV,
      liquidationThreshold: 1.2, // Liquidate if collateral drops to 120% of loan value
    );

    // Create smart contract to hold collateral
    final contractId = await blockchain.createSmartContract(
      type: 'loan_agreement',
      participants: [borrowerId, 'lending_pool'],
      terms: {
        'principalAmount': amount,
        'interestRateAPY': interestRate,
        'durationDays': duration.inDays,
        'collateralAmount': collateralAmount,
        'collateralType': collateralType.name,
      },
      collateral: collateralAmount,
      userId: borrowerId,
    );

    final startDate = DateTime.now();
    final dueDate = startDate.add(duration);

    final loan = Loan(
      loanId: loanId,
      borrowerId: borrowerId,
      lenderId: 'lending_pool',
      terms: terms,
      startDate: startDate,
      dueDate: dueDate,
      smartContractId: contractId,
      status: LoanStatus.active,
    );

    _loans[loanId] = loan;
    _userLoans.putIfAbsent(borrowerId, () => []).add(loanId);

    // Transfer loan amount to borrower
    await blockchain.transferPyreal(
      fromUserId: 'lending_pool',
      toUserId: borrowerId,
      amount: amount,
      memo: 'Loan disbursement: $loanId',
    );

    _logger.i('Loan approved: $loanId - $amount ₱ at ${interestRate.toStringAsFixed(2)}% APY');
    _logger.i('Total repayment: ${terms.totalRepaymentAmount.toStringAsFixed(2)} ₱');

    return loan;
  }

  /// Make a loan payment
  Future<LoanPayment> makePayment({
    required String loanId,
    required double amount,
  }) async {
    final loan = _loans[loanId];
    if (loan == null) {
      throw Exception('Loan not found: $loanId');
    }

    if (loan.status != LoanStatus.active && loan.status != LoanStatus.repaying) {
      throw Exception('Loan not active: ${loan.status}');
    }

    // Verify borrower has sufficient balance
    final balance = await blockchain.getBalance(loan.borrowerId);
    if (balance < amount) {
      throw Exception('Insufficient balance: $balance ₱ < $amount ₱');
    }

    // Transfer payment to lending pool
    await blockchain.transferPyreal(
      fromUserId: loan.borrowerId,
      toUserId: 'lending_pool',
      amount: amount,
      memo: 'Loan payment: $loanId',
    );

    loan.amountRepaid += amount;
    loan.status = LoanStatus.repaying;

    final paymentId = _generatePaymentId();
    final payment = LoanPayment(
      paymentId: paymentId,
      loanId: loanId,
      amount: amount,
      paymentDate: DateTime.now(),
      memo: 'Payment ${loan.paymentHistory.length + 1}',
    );

    loan.paymentHistory.add(payment);

    _logger.i('Payment received: $amount ₱ for loan $loanId (${loan.percentageRepaid.toStringAsFixed(1)}% repaid)');

    // Check if loan fully repaid
    if (loan.amountRepaid >= loan.terms.totalRepaymentAmount) {
      await _completeLoan(loan);
    }

    return payment;
  }

  /// Complete a loan and release collateral
  Future<void> _completeLoan(Loan loan) async {
    loan.status = LoanStatus.completed;
    loan.completedDate = DateTime.now();

    _logger.i('Loan completed: ${loan.loanId}');

    // Release collateral from smart contract
    await blockchain.releaseCollateral(
      contractId: loan.smartContractId,
      beneficiary: loan.borrowerId,
    );

    // Update credit profile
    final profile = await getCreditProfile(loan.borrowerId);
    _creditProfiles[loan.borrowerId] = CreditProfile(
      userId: profile.userId,
      reputationScore: profile.reputationScore,
      computeHoursContributed: profile.computeHoursContributed,
      pyrealStaked: profile.pyrealStaked,
      successfulLoansCompleted: profile.successfulLoansCompleted + 1,
      defaultedLoans: profile.defaultedLoans,
      totalBorrowed: profile.totalBorrowed + loan.terms.principalAmount,
      totalRepaid: profile.totalRepaid + loan.amountRepaid,
    );

    _logger.i('Credit profile updated: +1 successful loan');
  }

  /// Join lending pool to earn passive income
  Future<void> joinLendingPool({
    required String userId,
    required double amount,
  }) async {
    _logger.i('User $userId joining lending pool with $amount ₱');

    // Verify balance
    final balance = await blockchain.getBalance(userId);
    if (balance < amount) {
      throw Exception('Insufficient balance: $balance ₱ < $amount ₱');
    }

    // Transfer to pool
    await blockchain.transferPyreal(
      fromUserId: userId,
      toUserId: 'lending_pool',
      amount: amount,
      memo: 'Joined lending pool',
    );

    final currentStake = _mainPool.lenders[userId] ?? 0.0;
    _mainPool.lenders[userId] = currentStake + amount;

    _logger.i('Lender joined pool: $userId with $amount ₱');
  }

  /// Calculate lender's earnings from pool
  Future<double> calculateLenderEarnings(String userId) async {
    final stake = _mainPool.lenders[userId] ?? 0.0;
    if (stake == 0) return 0.0;

    // Calculate share of pool earnings
    final poolShare = stake / _mainPool.totalPoolSize;
    final earnings = _mainPool.totalEarned * poolShare;

    return earnings;
  }

  /// Get all loans for a user
  List<Loan> getUserLoans(String userId) {
    final loanIds = _userLoans[userId] ?? [];
    return loanIds.map((id) => _loans[id]!).toList();
  }

  /// Get protocol statistics
  Map<String, dynamic> getProtocolStats() {
    final totalLoans = _loans.length;
    final activeLoans = _loans.values.where((l) => l.status == LoanStatus.active).length;
    final completedLoans = _loans.values.where((l) => l.status == LoanStatus.completed).length;
    final defaultedLoans = _loans.values.where((l) => l.status == LoanStatus.defaulted).length;

    final totalBorrowed = _loans.values.map((l) => l.terms.principalAmount).fold(0.0, (a, b) => a + b);
    final totalRepaid = _loans.values.map((l) => l.amountRepaid).fold(0.0, (a, b) => a + b);

    return {
      'totalLoans': totalLoans,
      'activeLoans': activeLoans,
      'completedLoans': completedLoans,
      'defaultedLoans': defaultedLoans,
      'totalBorrowed': totalBorrowed,
      'totalRepaid': totalRepaid,
      'poolSize': _mainPool.totalPoolSize,
      'poolUtilization': _mainPool.totalPoolSize > 0 ? _mainPool.totalLoaned / _mainPool.totalPoolSize : 0.0,
      'totalLenders': _mainPool.lenders.length,
      'currentAPY': _mainPool.currentAPY,
    };
  }

  // Helper methods

  double _calculateInterestRate(CreditProfile profile) {
    final range = _interestRateRanges[profile.tier]!;
    final minRate = range[0];
    final maxRate = range[1];

    // Fine-tune within tier based on credit score
    final scoreNormalized = profile.creditScore / 100;
    final rate = maxRate - (scoreNormalized * (maxRate - minRate));

    return rate;
  }

  String _generateLoanId() {
    return 'loan_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generatePaymentId() {
    return 'payment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
