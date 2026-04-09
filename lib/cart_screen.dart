import 'package:flutter/material.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'widgets/tamara_promotion_widget.dart';
import 'widgets/tabby_promotion_widget.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/loyalty_provider.dart';
import 'services/update_service.dart';
import 'providers/language_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.my_cart,
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
                  Icon(
                    FontAwesomeIcons.cartShopping,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.cart_empty,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];
                      return _buildCartItem(
                        context,
                        cart,
                        cartItem,
                        productId,
                        currencyProvider,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFreeShippingProgress(cart, currencyProvider),
                  const SizedBox(height: 20),
                  _buildCheckoutForm(context, cart, currencyProvider),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartProvider cart,
    CartItem cartItem,
    int productId,
    CurrencyProvider currencyProvider,
  ) {
    final product = cartItem.product;
    final imageUrl = product.images.isNotEmpty ? product.images[0].src : '';
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey(productId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removed_from_cart(product.name)),
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
          children: [Icon(Icons.delete, color: Colors.white)],
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
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.categories.isNotEmpty
                          ? product.categories[0].name
                          : 'Category',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cartItem.quantity}x',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isAdd = false,
  }) {
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

  Widget _buildCheckoutForm(
    BuildContext context,
    CartProvider cart,
    CurrencyProvider currencyProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildEarnedPointsBanner(cart),
          _buildDiscountCodeSection(cart),
          if (cart.totalAmount > 0)
            TamaraPromotionWidget(price: cart.totalAmount),
          if (cart.totalAmount > 0)
            TabbyPromotionWidget(price: cart.totalAmount),
          const SizedBox(height: 20),
          _buildPriceSummaryRow(
            '${l10n.subtotal} :',
            cart.subtotal,
            currencyProvider,
          ),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceSummaryRow(
              '${l10n.discount} :',
              cart.discountAmount,
              currencyProvider,
              isDiscount: true,
            ),
          ],
          const Divider(
            height: 24,
            thickness: 1,
            color: Color.fromARGB(255, 236, 236, 236),
          ),
          _buildPriceSummaryRow(
            '${l10n.total} :',
            cart.totalAmount,
            currencyProvider,
            isTotal: true,
          ),
          const SizedBox(height: 20),
          _buildCheckoutButton(context, cart),
        ],
      ),
    );
  }

  Widget _buildEarnedPointsBanner(CartProvider cart) {
    if (cart.subtotal <= 0) return const SizedBox.shrink();

    final loyalty = Provider.of<LoyaltyProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final bool isLoggedIn =
        auth.status == AuthStatus.authenticated && auth.customer != null;

    final earnedPoints = loyalty.calculateEarnedPoints(cart.subtotal);

    final l10n = AppLocalizations.of(context)!;
    final String titleText = isLoggedIn
        ? l10n.earn_points_banner_title
        : l10n.login_to_earn_points_title;
    final String subtitleText = isLoggedIn
        ? l10n.earn_points_banner_subtitle
        : l10n.login_to_earn_points_subtitle;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitleText,
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (earnedPoints > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '+$earnedPoints ${l10n.pts_suffix}',
                style: GoogleFonts.poppins(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountCodeSection(CartProvider cart) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.coupon_applied(cart.appliedCoupon!.code),
              style: GoogleFonts.poppins(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
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
              hintText: l10n.enter_discount_code,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: cart.isApplyingCoupon
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () {
                        if (_couponController.text.isNotEmpty) {
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          String? identifier;
                          if (auth.customer != null) {
                            identifier = auth.customer!.id.toString();
                          }
                          cart.applyCoupon(
                            _couponController.text.trim(),
                            userIdOrEmail: identifier,
                          );
                        }
                      },
                      child: Text(
                        l10n.apply,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPriceSummaryRow(
    String title,
    double amount,
    CurrencyProvider currencyProvider, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount
                ? Colors.green.shade700
                : (isTotal ? Colors.black : Colors.grey[600]),
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
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartProvider cart) {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: () {
        if (cart.items.isNotEmpty) {
          final firstItem = cart.items.values.first;
          final categoryName = firstItem.product.categories.isNotEmpty
              ? firstItem.product.categories.first.name
              : 'Category';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(categoryName: categoryName),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.cart_empty)));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ),
          Text(
            l10n.checkout,
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

  Widget _buildFreeShippingProgress(CartProvider cart, CurrencyProvider currencyProvider) {
    var updateInfo = UpdateService().updateInfo;
    if (updateInfo == null) return const SizedBox.shrink();

    bool isEnabled = updateInfo['free_shipping_enabled'] ?? false;
    if (!isEnabled) return const SizedBox.shrink();

    double minAmount = (updateInfo['free_shipping_min_amount'] is num)
        ? (updateInfo['free_shipping_min_amount'] as num).toDouble()
        : double.tryParse(updateInfo['free_shipping_min_amount'].toString()) ?? 250.0;
    double currentAmount = cart.subtotal;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isArabic = languageProvider.appLocale.languageCode == 'ar';

    String msg = '';
    bool isSuccess = currentAmount >= minAmount;

    if (isSuccess) {
      msg = isArabic 
          ? (updateInfo['free_shipping_success_ar'] ?? 'مبروك! لقد تأهلت للحصول على شحن مجاني! 🚀') 
          : (updateInfo['free_shipping_success_en'] ?? 'Congratulations! You qualified for free shipping! 🚀');
    } else {
      double remaining = minAmount - currentAmount;
      String rawMsg = isArabic 
          ? (updateInfo['free_shipping_msg_ar'] ?? 'أضف منتجات بقيمة [amount] ر.س إضافية للحصول على شحن مجاني!')
          : (updateInfo['free_shipping_msg_en'] ?? 'Add [amount] SAR more to get free shipping!');
      
      // Replace [amount] with the formatted remaining amount + currency
      msg = rawMsg.replaceAll('[amount]', '${remaining.toStringAsFixed(2)} ${currencyProvider.currencySymbol}');
    }

    double progress = (currentAmount / minAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.local_shipping : Icons.local_shipping_outlined,
                color: isSuccess ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.notoSansArabic(
                    fontSize: 13,
                    fontWeight: isSuccess ? FontWeight.bold : FontWeight.w600,
                    color: isSuccess ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Progress track
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: MediaQuery.of(context).size.width * progress, // Approximation for width constraint
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
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
