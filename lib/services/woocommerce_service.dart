
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config.dart';
import '../models/product_model.dart';

class WooCommerceService {
  late final Dio _dio;

  WooCommerceService() {
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
        return (response.data as List)
            .map((p) => WooProduct.fromJson(p))
            .toList();
      } else {
        developer.log(
            'Error fetching products: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching products');
      return [];
    } catch (e, s) {
      developer.log('Unexpected error fetching products', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<WooProductVariation>> getProductVariations(int productId) async {
    try {
      final response = await _dio.get(
        '/products/$productId/variations',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'per_page': 100,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((v) => WooProductVariation.fromJson(v))
            .toList();
      } else {
        developer.log(
            'Error fetching product variations: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching product variations');
      return [];
    } catch (e, s) {
      developer.log('Unexpected error fetching product variations', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<WooProductCategory>> getCategories() async {
    try {
      final response = await _dio.get(
        '/products/categories',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'per_page': 100,
          'hide_empty': true,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) => WooProductCategory.fromJson(c))
            .toList();
      } else {
        developer.log(
            'Error fetching categories: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching categories');
      return [];
    } catch (e, s) {
      developer.log('Unexpected error fetching categories', error: e, stackTrace: s);
      return [];
    }
  }

  Future<String> getCurrencySymbol() async {
    try {
      final response = await _dio.get(
        '/data/currencies/current',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        // The API returns a map with a 'symbol' key.
        return response.data['symbol'] as String;
      } else {
        developer.log(
            'Error fetching currency symbol: Status ${response.statusCode}, Body: ${response.data}');
        return ''; // Return empty string on failure
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching currency symbol');
      return ''; // Return empty string on failure
    } catch (e, s) {
      developer.log('Unexpected error fetching currency symbol', error: e, stackTrace: s);
      return ''; // Return empty string on failure
    }
  }

  void _handleDioError(DioException e, StackTrace s, String context) {
    if (e.response != null) {
      developer.log(
          'Error $context: Status ${e.response?.statusCode}, Body: ${e.response?.data}',
          error: e,
          stackTrace: s);
    } else {
      developer.log(
          'Error $context: The connection errored. This might be a network issue or a server-side problem like CORS or bot protection.',
          error: e,
          stackTrace: s);
      developer.log('Dio message: ${e.message}');
    }
  }
}
