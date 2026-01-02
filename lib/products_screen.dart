import 'package:flutter/material.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  final String category;

  const ProductsScreen({super.key, required this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final WooCommerceService _wooCommerceService;
  late Future<List<WooProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _wooCommerceService = WooCommerceService();
    _productsFuture = _fetchProductsForCategory();
  }

  Future<List<WooProduct>> _fetchProductsForCategory() async {
    try {
      final categories = await _wooCommerceService.getCategories();
      Map<String, dynamic>? targetCategory;
      for (final cat in categories) {
        final catName = cat['name'] as String?;
        if (catName?.toLowerCase() == widget.category.toLowerCase()) {
          targetCategory = cat;
          break;
        }
      }

      if (targetCategory != null) {
        final categoryId = targetCategory['id'] as int?;
        if (categoryId != null) {
          return _wooCommerceService.getProducts(categoryId: categoryId);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('An error occurred in _fetchProductsForCategory: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Handle cart button press
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
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
              child: FutureBuilder<List<WooProduct>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  } else {
                    final products = snapshot.data!;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          imageUrl: (product.images.isNotEmpty)
                              ? product.images.first.src ?? ''
                              : '',
                          productName: product.name ?? 'No Name',
                          price: '${product.price} EUR',
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
