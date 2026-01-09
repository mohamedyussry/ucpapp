
import 'package:flutter/foundation.dart';
import '../services/woocommerce_service.dart';

class CurrencyProvider with ChangeNotifier {
  final WooCommerceService _wooCommerceService;

  String _currencySymbol = '';
  String? _currencyImageUrl;
  bool _isLoading = false;

  CurrencyProvider(this._wooCommerceService) {
    fetchCurrencySymbol();
  }

  String get currencySymbol => _currencySymbol;
  String? get currencyImageUrl => _currencyImageUrl;
  bool get isLoading => _isLoading;

  Future<void> fetchCurrencySymbol() async {
    _isLoading = true;
    notifyListeners();

    final rawHtml = await _wooCommerceService.getCurrencySymbol();
    
    // Store the cleaned text symbol as a fallback
    _currencySymbol = _cleanHtml(rawHtml);

    // Try to extract the image URL
    _currencyImageUrl = _extractImageUrl(rawHtml);

    _isLoading = false;
    notifyListeners();
  }

  String _cleanHtml(String htmlString) {
    // Removes HTML tags and entities to get plain text
    final RegExp htmlRegExp = RegExp(r"<[^>]*>|&[^;]+;");
    return htmlString.replaceAll(htmlRegExp, '').trim();
  }

  String? _extractImageUrl(String htmlString) {
    // Extracts the src attribute from an <img> tag
    final RegExp imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"'
    );
    final match = imgRegExp.firstMatch(htmlString);
    return match?.group(1); // group(1) captures the URL
  }
}
