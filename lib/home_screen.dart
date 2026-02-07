import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
// Home Widgets
import 'widgets/home/home_search_header.dart';
import 'widgets/home/home_slider.dart';
import 'widgets/home/home_promo_grid.dart';
import 'widgets/home/home_categories.dart';
import 'widgets/home/home_brands.dart';
import 'widgets/home/home_loyalty_section.dart';
import 'widgets/home/home_featured_products.dart';

import 'l10n/generated/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Hide status bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            const HomeSearchHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Add refresh logic if needed
                  setState(() {});
                },
                color: Colors.orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const HomeSlider(),
                      const HomePromoGrid(),
                      const SizedBox(height: 16),
                      const HomeCategories(),
                      HomeFeaturedProducts(
                        title: l10n.best_sellers,
                        isFeatured: true,
                      ),
                      const SizedBox(height: 24),
                      const HomeBrands(),
                      const SizedBox(height: 24),
                      const HomeLoyaltySection(),
                      const SizedBox(height: 16),
                      HomeFeaturedProducts(title: l10n.new_arrivals),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}
