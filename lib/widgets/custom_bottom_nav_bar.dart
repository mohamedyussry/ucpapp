import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/wishlist_screen.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/my_orders_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/self_care_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return; // Do nothing if already on the same screen

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => const HomeScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Categories
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const SelfCareScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Orders
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => const MyOrdersScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 3: // Favorites
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const WishlistScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const ProfileScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.tableCellsLarge, size: 20),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.box, size: 20),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.heart, size: 20),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user, size: 20),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }
}
