
import 'package:flutter/foundation.dart';
import '../services/woocommerce_service.dart';

class CurrencyProvider with ChangeNotifier {
  final WooCommerceService _wooCommerceService;
  String _currencySymbol = '';
  bool _isLoading = false;

  CurrencyProvider(this._wooCommerceService) {
    fetchCurrencySymbol();
  }

  String get currencySymbol => _currencySymbol;
  bool get isLoading => _isLoading;

  Future<void> fetchCurrencySymbol() async {
    _isLoading = true;
    notifyListeners();

    _currencySymbol = await _wooCommerceService.getCurrencySymbol();

    _isLoading = false;
    notifyListeners();
  }
}
