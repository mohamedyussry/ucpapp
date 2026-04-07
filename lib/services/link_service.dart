import 'dart:async';
import 'dart:developer' as developer;
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/product_detail_screen.dart';
import 'package:myapp/services/woocommerce_service.dart';

class LinkService {
  static final LinkService _instance = LinkService._internal();
  factory LinkService() => _instance;
  LinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final WooCommerceService _wooService = WooCommerceService();

  void initialize() {
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // 1. Handle link when app is closed and opened by link
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      developer.log('LinkService: Error getting initial link: $e');
    }

    // 2. Handle link when app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleLink(uri);
      }
    }, onError: (err) {
      developer.log('LinkService: Stream error: $err');
    });
  }

  void _handleLink(Uri uri) async {
    developer.log('LinkService: Handling link: $uri');

    // Expected format: https://ucpksa.com/product/product-slug/
    if (uri.pathSegments.contains('product')) {
      final int productIndex = uri.pathSegments.indexOf('product');
      if (uri.pathSegments.length > productIndex + 1) {
        final String slug = uri.pathSegments[productIndex + 1];
        if (slug.isNotEmpty) {
          _navigateToProduct(slug);
        }
      }
    }
  }

  Future<void> _navigateToProduct(String slug) async {
    developer.log('LinkService: Navigating to product with slug: $slug');
    
    // Show loading if possible or just fetch
    final product = await _wooService.getProductBySlug(slug);
    
    if (product != null) {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } else {
      developer.log('LinkService: Product not found for slug: $slug');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
