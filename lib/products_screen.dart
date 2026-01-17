
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/widgets/cart_badge.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';

class ProductsScreen extends StatefulWidget {
  final String category;

  const ProductsScreen({super.key, required this.category});

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
    _fetchProductsForCategory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProductsForCategory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final categories = await _wooCommerceService.getCategories();
      WooProductCategory? targetCategory;
      for (final cat in categories) {
        if (cat.name.toLowerCase() == widget.category.toLowerCase()) {
          targetCategory = cat;
          break;
        }
      }

      if (targetCategory != null) {
        final products = await _wooCommerceService.getProducts(categoryId: targetCategory.id);
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allProducts = [];
          _filteredProducts = [];
          _isLoading = false;
        });
      }
    } catch (e, s) {
      developer.log('An error occurred in _fetchProductsForCategory', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Failed to load products. Please try again later.';
        _isLoading = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.toUpperCase()),
        actions: const [
          CartBadge(),
        ],
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
                  hintText: 'Search Products',
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
            Expanded(
              child: _buildProductGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (_filteredProducts.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return const Center(child: Text('No products found matching your search.'));
      }
      return const Center(child: Text('No products available in this category.'));
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
}
