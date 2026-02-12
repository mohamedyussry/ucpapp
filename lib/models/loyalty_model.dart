class LoyaltyData {
  final int pointsBalance;
  final int currentTierId;
  final String tierName;
  final double spendingLast12Months;

  LoyaltyData({
    required this.pointsBalance,
    required this.currentTierId,
    required this.tierName,
    required this.spendingLast12Months,
  });

  factory LoyaltyData.fromJson(Map<String, dynamic> json) {
    String rawTier = json['tier_name']?.toString() ?? 'Basic';
    // If API returns 'none' or is empty, fallback to 'Basic'
    if (rawTier.isEmpty || rawTier.toLowerCase() == 'none') {
      rawTier = 'Basic';
    }

    return LoyaltyData(
      pointsBalance: json['points_balance'] ?? 0,
      currentTierId: json['current_tier_id'] ?? 0,
      tierName: rawTier,
      spendingLast12Months: (json['spending_last_12_months'] ?? 0).toDouble(),
    );
  }
}

class PointHistory {
  final String id;
  final String userId;
  final String points;
  final String operation;
  final String orderId;
  final String creationDate;

  PointHistory({
    required this.id,
    required this.userId,
    required this.points,
    required this.operation,
    required this.orderId,
    required this.creationDate,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      points: json['points']?.toString() ?? '0',
      operation: json['operation'] ?? '',
      orderId: json['order_id']?.toString() ?? '',
      creationDate: json['creation_date'] ?? '',
    );
  }
}

class LoyaltyTier {
  final String id;
  final String name;
  final String minSpending;
  final String pointsPer100;
  final String tierOrder;

  LoyaltyTier({
    required this.id,
    required this.name,
    required this.minSpending,
    required this.pointsPer100,
    required this.tierOrder,
  });

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) {
    return LoyaltyTier(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      minSpending: json['min_spending']?.toString() ?? '0',
      pointsPer100: json['points_per_100']?.toString() ?? '0',
      tierOrder: json['tier_order']?.toString() ?? '1',
    );
  }
}
