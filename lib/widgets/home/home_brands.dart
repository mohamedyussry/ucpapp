import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/products_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myapp/screens/brands_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeBrands extends StatefulWidget {
  const HomeBrands({super.key});

  @override
  State<HomeBrands> createState() => _HomeBrandsState();
}

class _HomeBrandsState extends State<HomeBrands> {
  final WooCommerceService _wooService = WooCommerceService();
  List<WooBrand> _brands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    try {
      final brands = await _wooService.getBrands();
      if (mounted) {
        setState(() {
          // جلب الماركات التي لديها خيار الظهور في التطبيق مفعل فقط، بغض النظر عن وجود صورة
          _brands = brands.where((b) => b.isVisibleInApp).toList();
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

    if (_brands.isEmpty) return const SizedBox.shrink();

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
                l10n.shop_by_brands,
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
                      builder: (context) => const BrandsScreen(),
                    ),
                  );
                },
                child: Text(
                  l10n.see_all,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240, // زيادة الارتفاع ليتناسب مع التنسيق الطولي في الصورة
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _brands.length,
            itemBuilder: (context, index) {
              final brand = _brands[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductsScreen(
                        brandId: brand.id,
                        brandName: brand.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150, // عرض البطاقة لتعطي التنسيق الطولي المطلوب
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: brand.image != null
                        ? CachedNetworkImage(
                            imageUrl: brand.image!.src,
                            fit: BoxFit.cover,
                            width: 150,
                            height: 240,
                            placeholder: (context, url) =>
                                _buildBrandPlaceholder(),
                            errorWidget: (context, url, error) =>
                                _buildBrandPlaceholder(),
                          )
                        : _buildBrandPlaceholder(),
                  ),
                ),
              );
            },
          ),
        ),
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
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.business, color: Colors.grey, size: 40),
      ),
    );
  }
}
