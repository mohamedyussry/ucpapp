
import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/wishlist_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/widgets/cart_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final WooProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  final WooCommerceService _wooCommerceService = WooCommerceService();

  // State for variations
  List<WooProductVariation> _variations = [];
  WooProductVariation? _selectedVariation;
  final Map<String, String> _selectedOptions = {};
  bool _isLoadingVariations = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.type == 'variable') {
      _fetchVariations();
    } else {
      _selectedVariation = null;
    }
  }

  void _fetchVariations() async {
    setState(() {
      _isLoadingVariations = true;
    });
    try {
      final variations = await _wooCommerceService.getProductVariations(widget.product.id);
      setState(() {
        _variations = variations;
        if (widget.product.attributes.isNotEmpty) {
          for (var attr in widget.product.attributes) {
            if (attr.options.isNotEmpty) {
              _selectedOptions[attr.name] = attr.options.first;
            }
          }
          _updateSelectedVariation();
        }
        _isLoadingVariations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVariations = false;
      });
    }
  }

  void _updateSelectedVariation() {
    if (_variations.isEmpty) return;

    _selectedVariation = _variations.firstWhere(
      (v) => v.attributes.every((attr) {
        return _selectedOptions[attr['name']] == attr['option'];
      }),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          CartBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(),
              const SizedBox(height: 24),
              _buildProductInfo(),
              const SizedBox(height: 24),
              if (widget.product.type == 'variable') _buildAttributeSelectors(),
              const SizedBox(height: 24),
              _buildStockInfo(),
              const SizedBox(height: 32),
              _buildDescription(),
              const SizedBox(height: 100), // Space for the bottom bar
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildImageCarousel() {
    final images = _selectedVariation?.image != null
        ? [_selectedVariation!.image!]
        : widget.product.images;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index].src,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          SmoothPageIndicator(
            controller: _pageController,
            count: images.length,
            effect: const WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Colors.black,
              dotColor: Colors.grey,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildProductInfo() {
    final brand = "Medicube"; // Dummy brand
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          brand.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.product.ratingCount > 0) _buildRatingInfo(),
        const SizedBox(height: 12),
        _buildPrice(),
      ],
    );
  }

  Widget _buildRatingInfo() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          widget.product.averageRating.toStringAsFixed(1),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          "(${widget.product.ratingCount} Reviews)",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    final price = _selectedVariation?.price ?? widget.product.price;
    final regularPrice = _selectedVariation?.regularPrice ?? widget.product.regularPrice;
    final salePrice = _selectedVariation?.salePrice ?? widget.product.salePrice;

    double? displayPrice = price;
    double? originalPrice;
    int? discount;

    if (salePrice != null && regularPrice != null && regularPrice > salePrice) {
      displayPrice = salePrice;
      originalPrice = regularPrice;
      discount = ((regularPrice - salePrice) / regularPrice * 100).round();
    } else if (regularPrice != null && regularPrice > 0) {
      displayPrice = price;
      originalPrice = (price != null && price < regularPrice) ? regularPrice : null;
      if (originalPrice != null && displayPrice != null) {
        discount = ((originalPrice - displayPrice) / originalPrice * 100).round();
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
             Text(
              '${displayPrice?.toStringAsFixed(2) ?? 'N/A'} ',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            _buildCurrencyDisplay(currencyProvider, 22),
          ],
        ),
        if (originalPrice != null) ...[
          const SizedBox(width: 8),
           Row(
             children: [
                Text(
                  '${originalPrice.toStringAsFixed(2)} ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                _buildCurrencyDisplay(currencyProvider, 16, color: Colors.grey),
             ],
           ),
        ],
        if (discount != null && discount > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '-$discount%',
              style: GoogleFonts.poppins(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttributeSelectors() {
    if (_isLoadingVariations) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.product.attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.product.attributes.map((attribute) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attribute.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: attribute.options.map((option) {
                final isSelected = _selectedOptions[attribute.name] == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedOptions[attribute.name] = option;
                      _updateSelectedVariation();
                    });
                  },
                  selectedColor: Colors.black,
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStockInfo() {
    final stockStatus = _selectedVariation?.stockStatus ?? widget.product.stockStatus;
    final isInStock = stockStatus == 'instock';

    return Column(
      children: [
        _infoRow(
          FontAwesomeIcons.box,
          isInStock ? "In stock" : "Out of stock",
          isInStock ? Colors.green.shade700 : Colors.red.shade700,
        ),
        const SizedBox(height: 12),
        _infoRow(FontAwesomeIcons.truck, "Free Delivery", Colors.black),
        const SizedBox(height: 12),
        _infoRow(FontAwesomeIcons.store, "Available in nearest store", Colors.black),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        FaIcon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final description = widget.product.description.replaceAll(RegExp(r'<[^>]*>'), '');
    return Text(
      description,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  Widget _buildBottomBar() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final stockStatus = _selectedVariation?.stockStatus ?? widget.product.stockStatus;
    final isInStock = stockStatus == 'instock';

    final productToAdd = widget.product.type == 'variable' && _selectedVariation != null
        ? WooProduct(
            id: _selectedVariation!.id,
            name: "${widget.product.name} - ${_selectedOptions.values.join(', ')}",
            type: 'variation',
            price: _selectedVariation!.price,
            regularPrice: _selectedVariation!.regularPrice,
            salePrice: _selectedVariation!.salePrice,
            images: _selectedVariation!.image != null ? [_selectedVariation!.image!] : widget.product.images,
            description: widget.product.description, 
            permalink: widget.product.permalink,
            categories: widget.product.categories,
            attributes: [],
            stockStatus: _selectedVariation!.stockStatus,
            stockQuantity: _selectedVariation!.stockQuantity,
            averageRating: widget.product.averageRating, 
            ratingCount: widget.product.ratingCount,
          )
        : widget.product;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              final isFavorite = wishlist.isFavorite(widget.product.id);
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    wishlist.toggleWishlist(widget.product);
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: isInStock
                  ? () {
                      cart.addItem(productToAdd);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${productToAdd.name} to cart!'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              cart.removeSingleItem(productToAdd.id);
                            },
                          ),
                        ),
                      );
                    }
                  : null, // Disable button if out of stock
              style: ElevatedButton.styleFrom(
                backgroundColor: isInStock ? Colors.orange : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isInStock ? 'Add to cart' : 'Out of Stock',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDisplay(CurrencyProvider currencyProvider, double size, {Color? color}) {
    final currencyImageUrl = currencyProvider.currencyImageUrl;
    final currencySymbol = currencyProvider.currencySymbol;

    final style = GoogleFonts.poppins(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: color ?? Colors.black,
    );

    if (currencyImageUrl != null && currencyImageUrl.isNotEmpty) {
      return Image.network(
        currencyImageUrl,
        height: size, // Adjust size as needed
        color: color,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to text if image fails to load
          return Text(currencySymbol, style: style);
        },
      );
    } else {
      return Text(currencySymbol, style: style);
    }
  }
}
