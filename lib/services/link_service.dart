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

  // Debouncing logic
  String? _lastProcessedLink;
  DateTime? _lastProcessTime;

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
    final String linkString = uri.toString();
    final now = DateTime.now();

    // Prevent processing the same link multiple times within 1 second
    if (_lastProcessedLink == linkString && 
        _lastProcessTime != null && 
        now.difference(_lastProcessTime!).inSeconds < 1) {
      developer.log('LinkService: Ignoring duplicate link: $linkString');
      return;
    }

    _lastProcessedLink = linkString;
    _lastProcessTime = now;
    
    developer.log('LinkService: Handling link: $uri');

    // Handle Custom Scheme: ucpapp://product/slug
    // Handle HTTPS: https://ucpksa.com/product/slug/
    
    String? slug;
    
    if (uri.scheme == 'ucpapp') {
      if (uri.host == 'product' && uri.pathSegments.isNotEmpty) {
        // ucpapp://product/slug
        slug = uri.pathSegments.first;
      } else if (uri.pathSegments.contains('product')) {
        // ucpapp:///product/slug (alternative)
        final int index = uri.pathSegments.indexOf('product');
        if (uri.pathSegments.length > index + 1) {
          slug = uri.pathSegments[index + 1];
        }
      } else if (uri.host.isNotEmpty && uri.host != 'product') {
        // ucpapp://slug (backward compatibility or short link)
        slug = uri.host;
      }
    } else {
      // Standard HTTPS/HTTP logic for ucpksa.com
      developer.log('LinkService: Parsing web link segments: ${uri.pathSegments}');
      
      // Look for slug in paths like: /product/slug/ or /shop/slug/
      if (uri.pathSegments.contains('product')) {
        final int index = uri.pathSegments.indexOf('product');
        if (uri.pathSegments.length > index + 1) {
          slug = uri.pathSegments[index + 1];
        }
      } else if (uri.pathSegments.contains('shop')) {
        final int index = uri.pathSegments.indexOf('shop');
        if (uri.pathSegments.length > index + 1) {
          slug = uri.pathSegments[index + 1];
        }
      } else if (uri.pathSegments.isNotEmpty) {
        // Fallback: Use the last non-empty segment as a potential slug
        // This helps if the URL is domain.com/product-slug/ (custom permalink)
        final nonEmptySegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (nonEmptySegments.isNotEmpty) {
          slug = nonEmptySegments.last;
        }
      }
    }

    if (slug != null && slug.isNotEmpty) {
      _navigateToProduct(slug);
    }
  }

  Future<void> _navigateToProduct(String slug) async {
    developer.log('LinkService: Navigating to product with slug: $slug');
    
    // 1. Wait for context to be available (especially for Cold Starts)
    BuildContext? context;
    int retries = 0;
    const int maxRetries = 10; // Wait up to 5 seconds (10 * 500ms)

    while (retries < maxRetries) {
      context = MyApp.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        developer.log('LinkService: Context is ready after ${retries * 500}ms');
        break;
      }
      
      developer.log('LinkService: Waiting for context... (Attempt ${retries + 1})');
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (context == null) {
      developer.log('LinkService: Failed to get context after multiple retries.');
      return;
    }

    // 2. Fetch product data
    // It's better to fetch while waiting if possible, but let's be safe
    final product = await _wooService.getProductBySlug(slug);
    
    if (product != null) {
      // Ensure we still have a valid context after the async fetch
      if (MyApp.navigatorKey.currentContext != null) {
        Navigator.push(
          MyApp.navigatorKey.currentContext!,
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
