
import 'package:flutter/material.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductDetailScreen extends StatefulWidget {
  final WooProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  String _selectedSize = "30ml"; // Default selected size

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
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              // Navigate to cart
            },
          ),
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
              _buildSizeSelector(),
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
    final images = widget.product.images;
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index].src ?? '',
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          ),
        ),
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
      ],
    );
  }

  Widget _buildProductInfo() {
    // Dummy brand for display, as it's not in WooProduct model
    final brand = "Medicube";
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
          widget.product.name ?? 'No Name',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              "4.8", // Static for now
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              "(217 Reviews)", // Static for now
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPrice(),
      ],
    );
  }

  Widget _buildPrice() {
    final salePrice = double.tryParse(widget.product.salePrice?.toString() ?? '');
    final regularPrice = double.tryParse(widget.product.regularPrice?.toString() ?? '');
    final price = double.tryParse(widget.product.price?.toString() ?? '');
    
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
        Text(
          '${displayPrice?.toStringAsFixed(2) ?? 'N/A'} EUR',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (originalPrice != null) ...[
          const SizedBox(width: 8),
          Text(
            '${originalPrice.toStringAsFixed(2)} EUR',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
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

  Widget _buildSizeSelector() {
    // Assuming static sizes for now
    final sizes = ["30ml", "100ml"];
    return Row(
      children: sizes.map((size) {
        final isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSize = size;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Text(
              size,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockInfo() {
    return Column(
      children: [
        _infoRow(FontAwesomeIcons.box, "in stock", Colors.green),
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
      // Simple regex to strip HTML tags
      final description = widget.product.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? 'No description available.';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {
                // Handle favorite action
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Handle add to cart
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add to cart',
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
}

