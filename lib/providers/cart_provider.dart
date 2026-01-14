
import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';

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
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subTotal;
    });
    return total;
  }

  void addItem(WooProduct product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) {
          existingCartItem.increment();
          return existingCartItem;
        },
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existingCartItem) {
        existingCartItem.decrement();
        return existingCartItem;
      });
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
