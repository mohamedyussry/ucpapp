import 'package:flutter/material.dart';
import 'package:myapp/models/coupon_model.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class CartItem {
  final WooProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  void increment() {
    quantity++;
  }

  void decrement() {
    quantity--;
  }

  double get subTotal {
    final price = product.price ?? 0.0;
    return price * quantity;
  }

  Map<String, dynamic> toJson() {
    return {'product': product.toJson(), 'quantity': quantity};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: WooProduct.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  final WooCommerceService _wooCommerceService = WooCommerceService();
  final Map<int, CartItem> _items = {};

  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  bool _isApplyingCoupon = false;
  String? _couponErrorMessage;

  CartProvider() {
    _loadCart();
  }

  // Persistence logic
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      );
      await prefs.setString('shopping_cart', json.encode(cartData));
      developer.log('Cart saved to local storage.');
    } catch (e) {
      developer.log('Error saving cart: $e');
    }
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('shopping_cart');
      if (cartString != null) {
        final Map<String, dynamic> decodedData = json.decode(cartString);
        decodedData.forEach((key, value) {
          final productId = int.parse(key);
          _items[productId] = CartItem.fromJson(value);
        });
        _recaculateDiscountOnCartChange();
        notifyListeners();
        developer.log(
          'Cart loaded from local storage: ${_items.length} items.',
        );
      }
    } catch (e) {
      developer.log('Error loading cart: $e');
    }
  }

  // Getters
  Map<int, CartItem> get items => {..._items};
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.subTotal);
  double get discountAmount => _discountAmount;
  Coupon? get appliedCoupon => _appliedCoupon;
  bool get isApplyingCoupon => _isApplyingCoupon;
  String? get couponErrorMessage => _couponErrorMessage;

  double get totalAmount {
    final total = subtotal - _discountAmount;
    return total > 0 ? total : 0.0; // Ensure total is not negative
  }

  // Coupon Logic
  Future<void> applyCoupon(String code) async {
    _isApplyingCoupon = true;
    _couponErrorMessage = null;
    notifyListeners();

    final coupon = await _wooCommerceService.validateCoupon(code);

    if (coupon == null) {
      _couponErrorMessage = 'Invalid coupon code.';
    } else {
      // Validate coupon restrictions
      final validationError = _validateCouponRestrictions(coupon);
      if (validationError != null) {
        _couponErrorMessage = validationError;
      } else {
        _appliedCoupon = coupon;
        _calculateDiscount();
      }
    }

    // If there was an error, reset the coupon state
    if (_couponErrorMessage != null) {
      _appliedCoupon = null;
      _discountAmount = 0.0;
    }

    _isApplyingCoupon = false;
    notifyListeners();
  }

  String? _validateCouponRestrictions(Coupon coupon) {
    // 1. Check expiry date
    if (coupon.dateExpires != null && coupon.dateExpires!.isNotEmpty) {
      try {
        // WooCommerce date format is like "2024-08-15T23:59:59"
        final expiryDate = DateTime.parse(coupon.dateExpires!);
        if (expiryDate.isBefore(DateTime.now())) {
          return 'This coupon has expired.';
        }
      } catch (e) {
        // Could not parse the date, better to log this and maybe allow it.
      }
    }

    // 2. Check minimum spend
    final minSpend = double.tryParse(coupon.minimumAmount) ?? 0.0;
    if (minSpend > 0 && subtotal < minSpend) {
      return 'Your subtotal must be at least $minSpend to use this coupon.';
    }

    // 3. Check maximum spend
    final maxSpend = double.tryParse(coupon.maximumAmount) ?? 0.0;
    if (maxSpend > 0 && subtotal > maxSpend) {
      return 'Your subtotal must be no more than $maxSpend to use this coupon.';
    }

    // All checks passed
    return null;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountAmount = 0.0;
    _couponErrorMessage = null;
    notifyListeners();
  }

  void _calculateDiscount() {
    if (_appliedCoupon == null) return;

    final couponAmount = double.tryParse(_appliedCoupon!.amount) ?? 0.0;

    if (_appliedCoupon!.discountType == 'percent') {
      _discountAmount = subtotal * (couponAmount / 100);
    } else {
      // Assumes 'fixed_cart' or other fixed types
      _discountAmount = couponAmount;
    }

    // Ensure discount is not more than the subtotal
    if (_discountAmount > subtotal) {
      _discountAmount = subtotal;
    }
  }

  // Cart Management Logic
  void _recaculateDiscountOnCartChange() {
    if (_appliedCoupon != null) {
      final validationError = _validateCouponRestrictions(_appliedCoupon!);
      if (validationError != null) {
        // If the cart change makes the coupon invalid (e.g., subtotal drops below min spend),
        // remove the coupon and notify the user.
        removeCoupon();
        // Optionally, you could set a message to inform the user why the coupon was removed.
        // _couponErrorMessage = "Coupon '${_appliedCoupon!.code}' was removed because..."
      } else {
        _calculateDiscount();
      }
    }
  }

  void addItem(WooProduct product) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => existing..increment());
    } else {
      _items.putIfAbsent(product.id, () => CartItem(product: product));
    }
    _recaculateDiscountOnCartChange();
    _saveCart();
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => existing..decrement());
    } else {
      _items.remove(productId);
    }
    _recaculateDiscountOnCartChange();
    _saveCart();
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    _recaculateDiscountOnCartChange();
    _saveCart();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    removeCoupon(); // Also clears the coupon when the cart is cleared
    _saveCart();
    notifyListeners();
  }
}
