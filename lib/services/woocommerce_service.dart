import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:dio/dio.dart';
import '../config.dart';

class WooCommerceService {
  late final WooCommerce _wooCommerce;
  late final Dio _dio;

  WooCommerceService() {
    _wooCommerce = WooCommerce(
      baseUrl: Config.wooCommerceUrl,
      username: Config.consumerKey, // Using consumerKey as username
      password: Config.consumerSecret, // Using consumerSecret as password
      isDebug: true,
    );
    _dio = Dio();
  }

  // Changed categoryId type from String? to int?
  Future<List<WooProduct>> getProducts({int? categoryId}) async {
    try {
      final products = await _wooCommerce.getProducts(
        category: categoryId, // Now passing an int?
      );
      return products;
    } on DioException catch (e) {
      _handleDioError(e, 'fetching products');
      return [];
    } catch (e) {
      print('Unexpected error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final url = '${Config.wooCommerceUrl}/wp-json/wc/v3/products/categories';
    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'per_page': 100, // Fetch up to 100 categories
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        print(
            'Error fetching categories: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      _handleDioError(e, 'fetching categories');
      return [];
    } catch (e) {
      print('Unexpected error fetching categories: $e');
      return [];
    }
  }

  void _handleDioError(DioException e, String context) {
    if (e.response != null) {
      print(
          'Error $context: Status ${e.response?.statusCode}, Body: ${e.response?.data}');
    } else {
      print('Error $context: ${e.message}');
    }
  }
}
