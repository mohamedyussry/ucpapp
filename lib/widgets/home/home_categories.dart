import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/self_care_screen.dart';
import 'package:myapp/products_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class HomeCategories extends StatefulWidget {
  const HomeCategories({super.key});

  @override
  State<HomeCategories> createState() => _HomeCategoriesState();
}
// ... (skip lines)

class _HomeCategoriesState extends State<HomeCategories> {
  final WooCommerceService _wooService = WooCommerceService();
  List<WooProductCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _wooService.getCategories();
      if (mounted) {
        setState(() {
          // Sorting: Primary categories first, then sub-categories
          // Or just show all as they come from API
          _categories = categories;
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

    if (_categories.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.shop_by_category,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelfCareScreen(),
                    ),
                  );
                },
                child: Text(
                  l10n.see_all,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // حساب العرض الدقيق ليظهر 4 أقسام كاملة
              // نخصم الهوامش الجانبية (16+16=32) والمسافات بين العناصر (3 مسافات × 10 = 30)
              final double screenWidth = MediaQuery.of(context).size.width;
              const double horizontalPadding = 32.0;
              const double spacing = 30.0;
              final double columnWidth = (screenWidth - horizontalPadding - spacing) / 4;

              // تقسيم الأقسام إلى أزواج (كل زوج في عمود واحد لضمان صفين)
              List<List<WooProductCategory>> pairs = [];
              for (var i = 0; i < _categories.length; i += 2) {
                if (i + 1 < _categories.length) {
                  pairs.add([_categories[i], _categories[i + 1]]);
                } else {
                  pairs.add([_categories[i]]);
                }
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  final pair = pairs[index];
                  return Container(
                    width: columnWidth,
                    margin: EdgeInsets.only(
                      right: index == pairs.length - 1 ? 0 : 10,
                    ),
                    child: Column(
                      children: pair.map((cat) {
                        final imageUrl = cat.image?.src ?? '';
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsScreen(
                                    categoryId: cat.id,
                                    category: cat.name,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 65,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                const Icon(
                                                  Icons.category_outlined,
                                                  color: Colors.orange,
                                                  size: 25,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.category_outlined,
                                            color: Colors.orange,
                                            size: 25,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.notoSansArabic(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(width: 150, height: 20, color: Colors.white),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final double columnWidth = (screenWidth - 32 - 30) / 4;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: columnWidth,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        children: List.generate(2, (i) => Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 65,
                                height: 65,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
