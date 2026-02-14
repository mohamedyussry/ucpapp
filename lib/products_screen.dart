import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/widgets/cart_badge.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:myapp/widgets/home/home_search_header.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n/generated/app_localizations.dart';

class ProductsScreen extends StatefulWidget {
  final String? category;
  final int? categoryId; // إضافة دعم ID الفئة مباشرة
  final String? categorySlug;
  final int? brandId;
  final int? tagId;
  final String? brandName;
  final bool? featured;
  final String? orderby;
  final String? order;
  final String? customTitle;

  const ProductsScreen({
    super.key,
    this.category,
    this.categoryId,
    this.categorySlug,
    this.brandId,
    this.tagId,
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 20;

  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  List<int> _categoryIdsToFetch = [];

  @override
  void initState() {
    super.initState();
    _wooCommerceService = WooCommerceService();
    _scrollController.addListener(_onScroll);
    // تأخير التنفيذ للتأكد من جاهزية الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initAndFetch();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading &&
        _searchController.text.isEmpty) {
      _fetchProducts(loadMore: true);
    }
  }

  Future<void> _initAndFetch() async {
    if (widget.categoryId != null || widget.category != null) {
      await _resolveCategoryTree();
    }
    await _fetchProducts();
  }

  Future<void> _resolveCategoryTree() async {
    try {
      final allCategories = await _wooCommerceService.getCategories();
      int? rootId = widget.categoryId;

      if (rootId == null && widget.category != null) {
        final match = allCategories.firstWhere(
          (c) => c.name.toLowerCase() == widget.category!.toLowerCase(),
          orElse: () => WooProductCategory(id: -1, name: '', slug: ''),
        );
        if (match.id != -1) rootId = match.id;
      }

      if (rootId != null) {
        _categoryIdsToFetch = [rootId];
        // Find all children recursively
        void findChildren(int parentId) {
          final children = allCategories.where((c) => c.parent == parentId);
          for (final child in children) {
            _categoryIdsToFetch.add(child.id);
            findChildren(child.id);
          }
        }

        findChildren(rootId);
      }
    } catch (e) {
      developer.log('Error resolving category tree: $e');
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _hasMore = true;
        _allProducts = [];
        _filteredProducts = [];
      });
    }

    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      if (!loadMore) {
        // 1. Try cache for first page only
        final String cacheKey = _getCacheKey();
        final cachedData = await _wooCommerceService.getProductsFromCache(
          cacheKey,
        );
        if (cachedData.isNotEmpty && mounted) {
          setState(() {
            _allProducts = cachedData;
            _filteredProducts = cachedData;
            _isLoading = false;
          });
        }
      }

      // 2. Fetch from network
      List<WooProduct> networkProducts = [];

      if (_categoryIdsToFetch.isNotEmpty) {
        // Since getProducts currently takes one ID, we'll fetch them individually or try comma separated if supported
        // But the most reliable way for "merging" on client with pagination is tricky.
        // However, many WooCommerce APIs support category=id1,id2
        // Let's try to pass the first one for now, or if it's "all" merged, we might need a better strategy.
        // FOR NOW: Fetch from all relevant categories by making multiple requests if needed,
        // but that breaks global pagination.
        // ACTUAL WOOCREEST API TIP: You can pass an array of categories if the wrapper supports it.
        // Our service uses a single ID. I will modify the service to support a list or just use the first one if not.

        // Let's assume the server doesn't support multiple easily without plugin.
        // We will fetch for each category in the tree and merge if it's the first page? No.

        // Actually, if we want TRUE merging with pagination, we should fetch products for the main category
        // and hope WooCommerce is configured to "Include children".
        // IF NOT, we will fetch for all IDs.

        // Modification: Let's fetch for EACH category and combine. (Not ideal for 100+ categories but okay for 5-10)
        // OR better: Just fetch the first 20 from any of these?

        // We'll use the IDs one by one or just the parent if it's the only way.
        // EXPERIMENT: Pass comma-separated IDs to categoryId param in getProducts.
        // I will use a loop for now to be safe, but only fetch 20 total.

        // For simplicity and speed: Just fetch for the parent ID, assuming WooCommerce covers it.
        // IF the user specifically asked for "دمج", they might have issues with how products are assigned.

        networkProducts = await _wooCommerceService.getProducts(
          categoryId: _categoryIdsToFetch.join(','),
          categorySlug: widget.categorySlug,
          brandId: widget.brandId,
          tagId: widget.tagId,
          orderby: widget.orderby,
          order: widget.order,
          featured: widget.featured,
          perPage: _perPage,
          page: _currentPage,
          useCache: _currentPage == 1,
        );

        // If the result is empty and we have subcategories, try to fetch from them?
        // This is getting complex. Let's stick to the parent ID and if it has fewer than 20,
        // it might be because they are only in children.
      } else {
        networkProducts = await _wooCommerceService.getProducts(
          categoryId: widget.categoryId,
          categorySlug: widget.categorySlug,
          brandId: widget.brandId,
          tagId: widget.tagId,
          orderby: widget.orderby,
          order: widget.order,
          featured: widget.featured,
          perPage: _perPage,
          page: _currentPage,
          useCache: _currentPage == 1,
        );
      }

      if (mounted) {
        setState(() {
          if (loadMore) {
            _allProducts.addAll(networkProducts);
          } else {
            _allProducts = networkProducts;
          }
          _filteredProducts = _allProducts;
          _hasMore = networkProducts.length == _perPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, s) {
      developer.log('Error in _fetchProducts', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (_allProducts.isEmpty) {
            final l10n = AppLocalizations.of(context);
            _errorMessage = l10n?.failed_load_products ?? 'Error';
          }
        });
      }
    }
  }

  String _getCacheKey() {
    return 'products_${widget.categoryId}_${widget.categorySlug}_${widget.brandId}_${widget.tagId}_${widget.featured}_${widget.orderby}_${widget.order}_p$_currentPage';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [CartBadge()],
      ),
      body: Column(
        children: [
          const HomeSearchHeader(showTopBar: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildProductGrid(),
            ),
          ),
        ],
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
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredProducts.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index < _filteredProducts.length) {
          final product = _filteredProducts[index];
          return ProductCard(product: product);
        } else {
          return _buildSingleShimmer();
        }
      },
    );
  }

  Widget _buildSingleShimmer() {
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
        return _buildSingleShimmer();
      },
    );
  }
}
