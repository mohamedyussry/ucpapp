import 'package:flutter/foundation.dart';
import 'package:myapp/models/loyalty_model.dart';
import 'package:myapp/services/loyalty_service.dart';
import 'dart:developer' as developer;

class LoyaltyProvider with ChangeNotifier {
  final LoyaltyService _loyaltyService = LoyaltyService();

  LoyaltyData? _loyaltyData;
  List<LoyaltyTier> _tiers = [];
  Map<String, dynamic>? _settings;
  bool _isLoading = false;

  LoyaltyData? get loyaltyData => _loyaltyData;
  List<LoyaltyTier> get tiers => _tiers;
  Map<String, dynamic>? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _loyaltyService.getLoyaltyData();
      final tiersData = await _loyaltyService.getTiers();
      final settingsData = await _loyaltyService.getSettings();

      _loyaltyData = data;
      _tiers = tiersData;
      _settings = settingsData;
    } catch (e) {
      developer.log('Error initializing loyalty provider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates points to be earned for a given subtotal based on the user's tier.
  int calculateEarnedPoints(double amount) {
    if (_loyaltyData == null || _tiers.isEmpty) return 0;

    // Find the current tier by ID first, then fallback to name
    final currentTier = _tiers.firstWhere(
      (t) => t.id == _loyaltyData!.currentTierId.toString(),
      orElse: () => _tiers.firstWhere(
        (t) => t.name == _loyaltyData!.tierName,
        orElse: () => _tiers.first,
      ),
    );

    double pointsPer100 = double.tryParse(currentTier.pointsPer100) ?? 0;
    developer.log(
      'LOYALTY: Calculating points for tier ${currentTier.name} (${currentTier.id}) with rate $pointsPer100',
    );
    // Calculation: (Amount / 100) * points_per_100
    return (amount / 100 * pointsPer100).floor();
  }

  /// Calculates the discount value for a given points balance based on settings.
  double calculateDiscountValue(int points) {
    if (_settings == null || _settings!['conversion_rate'] == null) return 0.0;

    final rate = _settings!['conversion_rate'];
    int ratePoints = rate['points'] ?? 1;
    double rateValue = (rate['value'] ?? 0.0).toDouble();

    // Discount = (Points / ratePoints) * rateValue
    return (points / ratePoints) * rateValue;
  }

  /// Automatically calculates the max discount possible and points to use.
  Map<String, dynamic> getAutomaticDiscount(double subtotal) {
    if (_loyaltyData == null || _loyaltyData!.pointsBalance <= 0) {
      return {'discount': 0.0, 'points': 0};
    }

    double discountValue = calculateDiscountValue(_loyaltyData!.pointsBalance);

    // If discount exceeds subtotal, cap it
    if (discountValue > subtotal) {
      // Find exact points needed for subtotal
      final rate = _settings!['conversion_rate'];
      int ratePoints = rate['points'] ?? 1;
      double rateValue = (rate['value'] ?? 0.0).toDouble();

      if (rateValue > 0) {
        int pointsNeeded = (subtotal / rateValue * ratePoints).ceil();
        return {'discount': subtotal, 'points': pointsNeeded};
      }
    }

    return {'discount': discountValue, 'points': _loyaltyData!.pointsBalance};
  }

  Future<bool> commitPointsUpdate({
    required int userId,
    required int points,
    required String operation,
    int? orderId,
  }) async {
    bool success = await _loyaltyService.updatePoints(
      userId: userId,
      points: points,
      operation: operation,
      orderId: orderId,
    );
    if (success) {
      await initialize(); // Refresh data
    }
    return success;
  }
}
