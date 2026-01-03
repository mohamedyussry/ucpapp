
import 'package:flutter/foundation.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';

class FavoritesProvider with ChangeNotifier {
  final Map<int, WooProduct> _favorites = {};

  Map<int, WooProduct> get favorites => {..._favorites};

  bool isFavorite(int? productId) {
    if (productId == null) return false;
    return _favorites.containsKey(productId);
  }

  void toggleFavorite(WooProduct product) {
    if (product.id == null) return;
    
    if (_favorites.containsKey(product.id)) {
      _favorites.remove(product.id);
    } else {
      _favorites[product.id!] = product;
    }
    notifyListeners();
  }

  void clear() {
    _favorites.clear();
    notifyListeners();
  }
}
