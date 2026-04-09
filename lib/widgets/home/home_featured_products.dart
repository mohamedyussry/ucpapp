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
  final int? categoryId;
  final String? categorySlug;
  final int? tagId;
  const HomeFeaturedProducts({
    super.key,
    required this.title,
    this.isFeatured = false,
    this.categoryId,
    this.categorySlug,
    this.tagId,
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
      if (widget.categorySlug != null) {
        // جلب المنتجات عن طريق الـ Slug للفئة
        products = await _wooService.getProducts(
          categorySlug: widget.categorySlug,
          orderby: 'date',
          order: 'desc',
          perPage: 10,
        );
      } else if (widget.tagId != null) {
        // جلب المنتجات عن طريق الوسم (Tag)
        // جلب المنتجات من فئة محددة
        products = await _wooService.getProducts(
          categoryId: widget.categoryId,
          orderby: 'date',
          order: 'desc',
          perPage: 10,
        );
      } else if (widget.isFeatured) {
        // جلب المنتجات المميزة (المحددة بنجمة في ووردبريس)
        products = await _wooService.getProducts(featured: true, perPage: 10);

        // إذا لم يكن هناك منتجات مميزة، نجلب الأكثر مبيعاً أو تقييماً كاحتياط
        if (products.isEmpty) {
          products = await _wooService.getProducts(
            orderby: 'popularity',
            order: 'desc',
            perPage: 10,
          );
        }
      } else {
        // جلب أحدث المنتجات
        products = await _wooService.getProducts(
          orderby: 'date',
          order: 'desc',
          perPage: 10,
        );
      }

      if (mounted) {
        setState(() {
          _products = products;
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
                        featured:
                            (widget.categoryId == null &&
                                widget.categorySlug == null &&
                                widget.tagId == null)
                            ? widget.isFeatured
                            : null,
                        categoryId: widget.categoryId,
                        categorySlug: widget.categorySlug,
                        tagId: widget.tagId,
                        orderby:
                            (widget.categoryId != null ||
                                widget.categorySlug != null ||
                                widget.tagId != null)
                            ? 'date'
                            : (widget.isFeatured ? 'popularity' : 'date'),
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
          padding: const EdgeInsets.symmetric(horizontal: 5), // تقليل الهوامش الجانبية للحد الأدنى (5px)
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              const double spacing = 8.0; // مجموع المسافات بين الـ 3 منتجات (4px * 2)
              final double itemWidth = (screenWidth - spacing) / 3;

              return SizedBox(
                height: 260, // الارتفاع المتفق عليه ليكون العرض والارتفاع متناسقين
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: itemWidth,
                      margin: EdgeInsets.only(
                        right: index == _products.length - 1 ? 0 : 4,
                      ),
                      child: ProductCard(product: _products[index]),
                    );
                  },
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            height: 260,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final double itemWidth = (screenWidth - 8.0) / 3;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: itemWidth,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
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
