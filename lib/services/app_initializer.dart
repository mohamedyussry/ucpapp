import 'package:myapp/services/cache_service.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'dart:developer' as developer;

class AppInitializer {
  static final WooCommerceService _wooService = WooCommerceService();

  static Future<void> preloadData() async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      // 1. Initialize Cache
      await CacheService.init();

      // 2. Preload critical data in parallel
      // We use a timeout to ensure the app doesn't hang indefinitely on splash screen
      await Future.wait([
        _wooService.getCategories(),
        _wooService.getBrands(),
        _wooService.getProducts(featured: true, perPage: 10),
        _wooService.getProducts(orderby: 'date', order: 'desc', perPage: 10),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('Data preloading timed out, proceeding to app...');
          return [];
        },
      );

      developer.log(
        'App initialization completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      developer.log('Error during app initialization: $e');
    } finally {
      stopwatch.stop();
    }
  }
}
