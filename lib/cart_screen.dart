
import 'package:flutter/material.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'providers/cart_provider.dart';
import 'checkout_screen.dart'; // Import the new checkout screen
import 'widgets/custom_bottom_nav_bar.dart'; // Import the custom bottom nav bar

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Cart',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];
                      return _buildCartItem(context, cart, cartItem, productId, currencyProvider);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCheckoutForm(context, cart, currencyProvider),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart, CartItem cartItem, int productId, CurrencyProvider currencyProvider) {
    final product = cartItem.product;
    final imageUrl = product.images.isNotEmpty ? product.images[0].src : '';

    return Dismissible(
      key: ValueKey(productId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} removed from cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 1,
        shadowColor: Colors.grey.withAlpha((255 * 0.2).round()),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.categories.isNotEmpty ? product.categories[0].name : 'Category',
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${product.price ?? '0'} ',
                           style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildCurrencyDisplay(currencyProvider),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cartItem.quantity}x',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () {
                          cart.removeSingleItem(productId);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuantityButton(
                        icon: Icons.add,
                        isAdd: true,
                        onPressed: () {
                          cart.addItem(product);
                        },
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed, bool isAdd = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isAdd ? Colors.orange : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildCheckoutForm(BuildContext context, CartProvider cart, CurrencyProvider currencyProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildTextFieldWithIcon(hint: 'attach picture of prescriptions', icon: Icons.camera_alt_outlined),
          const SizedBox(height: 12),
          _buildDiscountCodeSection(cart),
          const SizedBox(height: 20),
          _buildPriceSummaryRow('Sub total :', cart.subtotal, currencyProvider),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceSummaryRow('Discount :', cart.discountAmount, currencyProvider, isDiscount: true),
          ],
          const Divider(height: 24, thickness: 1, color: Color.fromARGB(255, 236, 236, 236)),
          _buildPriceSummaryRow('Total :', cart.totalAmount, currencyProvider, isTotal: true),
          const SizedBox(height: 20),
          _buildCheckoutButton(context, cart),
        ],
      ),
    );
  }

  Widget _buildDiscountCodeSection(CartProvider cart) {
    if (cart.appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coupon applied: ${cart.appliedCoupon!.code}',
              style: GoogleFonts.poppins(color: Colors.green.shade800, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(Icons.clear, color: Colors.green.shade700),
              onPressed: () {
                cart.removeCoupon();
              },
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _couponController,
            decoration: InputDecoration(
              hintText: 'Enter Discount Code',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: cart.isApplyingCoupon
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () {
                        if (_couponController.text.isNotEmpty) {
                          cart.applyCoupon(_couponController.text.trim());
                        }
                      },
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
          if (cart.couponErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                cart.couponErrorMessage!,
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildTextFieldWithIcon({required String hint, required IconData icon}) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        suffixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPriceSummaryRow(String title, double amount, CurrencyProvider currencyProvider, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.green.shade700 : (isTotal ? Colors.black : Colors.grey[600]),
          ),
        ),
        Row(
          children: [
             if (isDiscount)
              Text(
                '-', // Add a minus sign for the discount
                style: GoogleFonts.poppins(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            Text(
              '${amount.toStringAsFixed(2)} ',
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isDiscount ? Colors.green.shade700 : Colors.black,
              ),
            ),
            _buildCurrencyDisplay(currencyProvider),
          ],
        )
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartProvider cart) {
    return ElevatedButton(
      onPressed: () {
        if (cart.items.isNotEmpty) {
          final firstItem = cart.items.values.first;
          final categoryName = firstItem.product.categories.isNotEmpty ? firstItem.product.categories.first.name : 'Category';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(
                categoryName: categoryName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your cart is empty.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ),
          Text(
            'Checkout',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 40), // To balance the layout
        ],
      ),
    );
  }

   Widget _buildCurrencyDisplay(CurrencyProvider currencyProvider) {
    final currencyImageUrl = currencyProvider.currencyImageUrl;
    final currencySymbol = currencyProvider.currencySymbol;

    if (currencyImageUrl != null && currencyImageUrl.isNotEmpty) {
      return Image.network(
        currencyImageUrl,
        height: 16, // Adjust size as needed
        errorBuilder: (context, error, stackTrace) {
          // Fallback to text if image fails to load
          return Text(currencySymbol);
        },
      );
    } else {
      return Text(currencySymbol);
    }
  }
}
