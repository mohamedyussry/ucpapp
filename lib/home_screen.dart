import 'package:flutter/material.dart';
import 'package:myapp/products_screen.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import './self_care_screen.dart';
import 'widgets/category_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CategoryBanner(
                title: 'Self Care',
                subtitle: 'Shop now',
                videoAsset: 'assets/home/self-care.mp4',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelfCareScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: CategoryBanner(
                title: 'Medicines',
                subtitle: 'Shop now',
                videoAsset: 'assets/home/medicines.mp4',
                showFloatingIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProductsScreen(category: 'Medicine'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}
