import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/wishlist_screen.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/my_orders_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/self_care_screen.dart';

import '../l10n/generated/app_localizations.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) {
      return; // Do nothing if already on the same screen
    }

    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const SelfCareScreen();
        break;
      case 2:
        page = const MyOrdersScreen();
        break;
      case 3:
        page = const WishlistScreen();
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.house, size: 20),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.tableCellsLarge, size: 20),
            label: l10n.categories,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.box, size: 20),
            label: l10n.orders,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.heart, size: 20),
            label: l10n.favorites,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.user, size: 20),
            label: l10n.profile,
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }
}
