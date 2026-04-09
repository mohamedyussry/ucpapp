import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/providers/currency_provider.dart';

import 'package:myapp/services/woocommerce_service.dart';
import '../product_detail_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'custom_cart_notification.dart';

class ProductCard extends StatefulWidget {
  final WooProduct product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static final Map<String, List<String>> _offersCache = {};
  List<String> _offers = [];
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final lang = Localizations.localeOf(context).languageCode;
      _fetchOffer(lang);
      _isInit = true;
    }
  }

  void _fetchOffer(String lang) async {
    final cacheKey = "${widget.product.id}_$lang";
    if (_offersCache.containsKey(cacheKey)) {
      setState(() {
        _offers = _offersCache[cacheKey]!;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = WooCommerceService();
      final offers = await service.getProductOffers(widget.product.id, lang);
      _offersCache[cacheKey] = offers;
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final imageUrl = widget.product.images.isNotEmpty ? widget.product.images[0].src : '';
    final productName = widget.product.name;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((255 * 0.1).round()),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6, // زيادة مساحة الصورة
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                    if (_offers.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            _offers.first.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, child) {
                          final isFavorite = wishlistProvider.isFavorite(
                            widget.product.id,
                          );
                          return GestureDetector(
                            onTap: () {
                              wishlistProvider.toggleWishlist(widget.product);
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withAlpha(
                                (255 * 0.8).round(),
                              ),
                              radius: 15,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4, // تقليل مساحة النصوص لتكون أكثر تماسكاً
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // تقليل البادينج
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed height for name
                      SizedBox(
                        height: 32, // تقليل الارتفاع لتقليل الفراغ
                        child: Text(
                          productName,
                          style: GoogleFonts.notoSansArabic(
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Reduced for 3-column layout
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Height-stable area for old price
                      SizedBox(
                        height: 18,
                        child: (widget.product.salePrice != null &&
                                widget.product.regularPrice != null &&
                                widget.product.salePrice! < widget.product.regularPrice!)
                            ? Row(
                                children: [
                                  Text(
                                    '${widget.product.regularPrice?.toStringAsFixed(2) ?? '0.00'} ',
                                    style: GoogleFonts.notoSansArabic(
                                      fontSize: 11, // Reduced
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.grey.shade500,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                  _buildCurrencyDisplay(
                                    currencyProvider,
                                    fontSize: 11,
                                    isGrey: true,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.product.price?.toStringAsFixed(2) ?? '0.00'} ',
                                    style: GoogleFonts.notoSansArabic(
                                      fontSize: 15, // Reduced for consistency
                                      fontWeight: FontWeight.bold,
                                      color: (widget.product.salePrice != null &&
                                              widget.product.regularPrice != null &&
                                              widget.product.salePrice! <
                                                  widget.product.regularPrice!)
                                          ? Colors.red.shade600
                                          : Colors.black87,
                                    ),
                                  ),
                                  _buildCurrencyDisplay(
                                    currencyProvider,
                                    fontSize: 14,
                                    isGrey: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              cart.addItem(widget.product);
                              CustomCartNotification.show(context, widget.product);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6), // Slightly smaller
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.cartPlus,
                                color: Colors.white,
                                size: 16, // Slightly smaller
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay(
    CurrencyProvider currencyProvider, {
    double fontSize = 18,
    bool isGrey = false,
  }) {
    final currencyImageUrl = currencyProvider.currencyImageUrl;
    final currencySymbol = currencyProvider.currencySymbol;

    final style = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: isGrey ? Colors.grey.shade500 : Colors.black87,
      decoration: isGrey ? TextDecoration.lineThrough : null,
      decorationColor: isGrey ? Colors.grey.shade500 : null,
      decorationThickness: isGrey ? 2 : null,
    );

    if (currencyImageUrl != null && currencyImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currencyImageUrl,
        height: fontSize,
        errorWidget: (context, url, error) {
          return Text(currencySymbol, style: style);
        },
      );
    } else {
      return Text(currencySymbol, style: style);
    }
  }
}
