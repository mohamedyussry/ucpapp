import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/cart_provider.dart';
import '../cart_screen.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 4.0),
          child: badges.Badge(
            showBadge: cart.itemCount > 0,
            badgeContent: Text(
              cart.itemCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: -2, end: 2),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.orange,
              padding: EdgeInsets.all(4),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
