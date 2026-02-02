import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/products_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeFeaturedProducts extends StatefulWidget {
  final String title;
  final bool isFeatured;
  const HomeFeaturedProducts({
    super.key,
    required this.title,
    this.isFeatured = false,
  });

  @override
  State<HomeFeaturedProducts> createState() => _HomeFeaturedProductsState();
}

class _HomeFeaturedProductsState extends State<HomeFeaturedProducts> {
  final WooCommerceService _wooService = WooCommerceService();
  List<WooProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      List<WooProduct> products;
      if (widget.isFeatured) {
        // جلب المنتجات المميزة (المحددة بنجمة في ووردبريس)
        products = await _wooService.getProducts(featured: true);

        // إذا لم يكن هناك منتجات مميزة، نجلب الأكثر مبيعاً أو تقييماً كاحتياط
        if (products.isEmpty) {
          products = await _wooService.getProducts(
            orderby: 'popularity',
            order: 'desc',
          );
        }
      } else {
        // جلب أحدث المنتجات
        products = await _wooService.getProducts(
          orderby: 'date',
          order: 'desc',
        );
      }

      if (mounted) {
        setState(() {
          _products = products
              .take(10)
              .toList(); // نكتفي بأول 10 منتجات للعرض السريع
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_products.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductsScreen(
                        featured: widget.isFeatured,
                        orderby: widget.isFeatured ? 'popularity' : 'date',
                        order: 'desc',
                        customTitle: widget.title,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.see_all,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double viewportFraction;

              if (screenWidth > 1200) {
                viewportFraction = 0.2; // 5 products
              } else if (screenWidth > 900) {
                viewportFraction = 0.25; // 4 products
              } else if (screenWidth > 600) {
                viewportFraction = 0.33; // 3 products
              } else {
                viewportFraction = 0.5; // 2 products
              }

              return CarouselSlider(
                options: CarouselOptions(
                  height: 330,
                  viewportFraction: viewportFraction,
                  enlargeCenterPage: false,
                  enableInfiniteScroll:
                      _products.length > (1 / viewportFraction).ceil(),
                  padEnds: false,
                  disableCenter: true,
                  scrollPhysics: const BouncingScrollPhysics(),
                ),
                items: _products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ProductCard(product: product),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(width: 150, height: 20, color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 330,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                double width;
                if (screenWidth > 1200)
                  width = screenWidth / 5;
                else if (screenWidth > 900)
                  width = screenWidth / 4;
                else if (screenWidth > 600)
                  width = screenWidth / 3;
                else
                  width = screenWidth / 2;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: width - 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
