
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  List<WooProduct> _wishlistItems = [];
  static const _wishlistKey = 'wishlist_items';

  List<WooProduct> get wishlistItems => _wishlistItems;

  WishlistProvider() {
    _loadWishlist();
  }

  // Load wishlist from shared preferences
  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistString = prefs.getString(_wishlistKey);
    if (wishlistString != null) {
      final List<dynamic> wishlistJson = json.decode(wishlistString);
      _wishlistItems = wishlistJson.map((item) => WooProduct.fromJson(item)).toList();
      notifyListeners();
    }
  }

  // Save wishlist to shared preferences
  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = _wishlistItems.map((item) => item.toJson()).toList();
    await prefs.setString(_wishlistKey, json.encode(wishlistJson));
  }

  bool isFavorite(int productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  void toggleWishlist(WooProduct product) {
    if (isFavorite(product.id)) {
      _wishlistItems.removeWhere((item) => item.id == product.id);
    } else {
      _wishlistItems.add(product);
    }
    _saveWishlist();
    notifyListeners();
  }
}
