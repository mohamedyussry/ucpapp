import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/products_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class HomePromoGrid extends StatefulWidget {
  const HomePromoGrid({super.key});

  @override
  State<HomePromoGrid> createState() => _HomePromoGridState();
}

class _HomePromoGridState extends State<HomePromoGrid> {
  final WooCommerceService _wooService = WooCommerceService();
  List<WooProductCategory> _promoCategories = [];
  bool _isLoading = true;

  final List<String> _targetCategoryNames = [
    'For Baby',
    'For Her',
    'For Him',
    'Medicine',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPromoCategories();
  }

  Future<void> _fetchPromoCategories() async {
    try {
      final allCategories = await _wooService.getCategories();
      if (mounted) {
        setState(() {
          // Filter categories to match target names (case-insensitive)
          _promoCategories = allCategories.where((cat) {
            return _targetCategoryNames.any(
              (target) => cat.name.toLowerCase() == target.toLowerCase(),
            );
          }).toList();

          // Re-order based on _targetCategoryNames order
          _promoCategories.sort((a, b) {
            int indexA = _targetCategoryNames.indexWhere(
              (name) => name.toLowerCase() == a.name.toLowerCase(),
            );
            int indexB = _targetCategoryNames.indexWhere(
              (name) => name.toLowerCase() == b.name.toLowerCase(),
            );
            return indexA.compareTo(indexB);
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getLocalizedCategoryName(BuildContext context, String originalName) {
    final l10n = AppLocalizations.of(context)!;
    switch (originalName.toLowerCase()) {
      case 'for baby':
        return l10n.cat_for_baby;
      case 'for her':
        return l10n.cat_for_her;
      case 'for him':
        return l10n.cat_for_him;
      case 'medicine':
        return l10n.cat_medicine;
      default:
        return originalName;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_promoCategories.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _promoCategories.length,
      itemBuilder: (context, index) {
        final category = _promoCategories[index];
        final imageUrl = category.image?.src ?? '';
        final displayName = _getLocalizedCategoryName(context, category.name);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductsScreen(category: category.name),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey[200],
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.35),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                displayName.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
