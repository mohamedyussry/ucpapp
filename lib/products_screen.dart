import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/widgets/cart_badge.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n/generated/app_localizations.dart';

class ProductsScreen extends StatefulWidget {
  final String? category;
  final int? categoryId; // إضافة دعم ID الفئة مباشرة
  final int? brandId;
  final String? brandName;
  final bool? featured;
  final String? orderby;
  final String? order;
  final String? customTitle;

  const ProductsScreen({
    super.key,
    this.category,
    this.categoryId,
    this.brandId,
    this.brandName,
    this.featured,
    this.orderby,
    this.order,
    this.customTitle,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final WooCommerceService _wooCommerceService;
  List<WooProduct> _allProducts = [];
  List<WooProduct> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _wooCommerceService = WooCommerceService();
    // تأخير التنفيذ للتأكد من جاهزية الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProducts();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 1. Try to load from cache first for instant UI
      final String cacheKey = _getCacheKey();
      final cachedData = await _wooCommerceService.getProductsFromCache(
        cacheKey,
      );

      if (cachedData.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allProducts = cachedData;
            _filteredProducts = cachedData;
            _isLoading = false;
          });
        }
      }

      // 2. Fetch from network in background/parallel
      int? targetCategoryId = widget.categoryId;

      // If we only have name, find the ID quickly
      if (targetCategoryId == null && widget.category != null) {
        final categories = await _wooCommerceService.getCategories();
        for (final cat in categories) {
          if (cat.name.toLowerCase() == widget.category!.toLowerCase()) {
            targetCategoryId = cat.id;
            break;
          }
        }
      }

      final List<WooProduct> networkProducts = await _wooCommerceService
          .getProducts(
            categoryId: targetCategoryId,
            brandId: widget.brandId,
            orderby: widget.orderby,
            order: widget.order,
            featured: widget.featured,
            perPage: 20, // Fetch small first for speed
          );

      if (mounted) {
        setState(() {
          _allProducts = networkProducts;
          _filteredProducts = networkProducts;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      developer.log(
        'An error occurred in _fetchProducts',
        error: e,
        stackTrace: s,
      );
      if (mounted && _allProducts.isEmpty) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage =
              l10n?.failed_load_products ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  String _getCacheKey() {
    return 'products_${widget.categoryId}_${widget.brandId}_${widget.featured}_${widget.orderby}_${widget.order}';
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _filterProducts();
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title =
        widget.customTitle ??
        widget.brandName ??
        widget.category?.toUpperCase() ??
        l10n.products;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [CartBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search_products,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // Handle filter button press
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildProductGrid() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_filteredProducts.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return Center(child: Text(l10n.no_products_matching));
      }
      return Center(child: Text(l10n.no_products_available));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }
}
