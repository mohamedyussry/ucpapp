import 'package:dio/dio.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../config.dart';

class WooCommerceService {
  late final Dio _dio;

  WooCommerceService() {
    // Initialize a single Dio instance for all network calls.
    // It's configured with the base URL and a User-Agent to bypass bot protection.
    _dio = Dio(
      BaseOptions(
        baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3',
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ),
    );
  }

  // Rewritten to use our reliable Dio instance.
  Future<List<WooProduct>> getProducts({int? categoryId}) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'per_page': '100',
      };

      if (categoryId != null) {
        queryParameters['category'] = categoryId.toString();
      }

      final response = await _dio.get(
        '/products',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        // Manually parse the JSON data into a list of WooProduct objects.
        return (response.data as List)
            .map((p) => WooProduct.fromJson(p))
            .toList();
      } else {
        print(
            'Error fetching products: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      _handleDioError(e, 'fetching products');
      return [];
    } catch (e) {
      print('Unexpected error fetching products: $e');
      return [];
    }
  }

  // This method already uses our reliable Dio instance.
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get(
        '/products/categories',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'per_page': 100,
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
      print(
          'Error $context: The connection errored. This might be a network issue or a server-side problem like CORS or bot protection.');
      print('Dio message: ${e.message}');
    }
  }
}
