
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:myapp/models/payment_method_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/providers/checkout_provider.dart';
import '../config.dart';
import '../models/order_payload_model.dart';
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

  Future<Map<String, dynamic>?> createOrder(OrderPayload payload) async {
    try {
      final response = await _dio.post(
        '/orders',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
        data: payload.toJson(),
      );

      if (response.statusCode == 201) {
        developer.log('Order created successfully: ${response.data}');
        return response.data as Map<String, dynamic>;
      } else {
        developer.log(
            'Error creating order: Status ${response.statusCode}, Body: ${response.data}');
        return null;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'creating order');
      return null;
    } catch (e, s) {
      developer.log('Unexpected error creating order', error: e, stackTrace: s);
      return null;
    }
  }

   Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _dio.get(
        '/payment_gateways',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((p) => PaymentMethod.fromJson(p))
            .where((p) => p.enabled) // Only return enabled payment methods
            .toList();
      } else {
        developer.log(
            'Error fetching payment methods: Status ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching payment methods');
      return [];
    } catch (e, s) {
      developer.log('Unexpected error fetching payment methods', error: e, stackTrace: s);
      return [];
    }
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

    Future<List<ShippingMethod>> getShippingMethodsForLocation(String country, String state, String postcode) async {
    try {
      // 1. Fetch all shipping zones at once.
      final zonesResponse = await _dio.get(
        '/shipping/zones',
        queryParameters: {
            'consumer_key': Config.consumerKey,
            'consumer_secret': Config.consumerSecret,
        },
      );

      if (zonesResponse.statusCode != 200 || zonesResponse.data == null) {
        developer.log('Failed to fetch shipping zones: ${zonesResponse.data}');
        return [];
      }

      final List<dynamic> allZones = zonesResponse.data;
      List<ShippingMethod> availableMethods = [];

      // 2. Create a list of futures to fetch methods for each zone.
      List<Future> methodFutures = [];

      for (var zone in allZones) {
        final zoneId = zone['id'];
        if (zoneId != null) {
          methodFutures.add(
            _dio.get(
              '/shipping/zones/$zoneId/methods',
              queryParameters: {
                'consumer_key': Config.consumerKey,
                'consumer_secret': Config.consumerSecret,
              },
            ).then((response) {
                if (response.statusCode == 200 && response.data is List) {
                    return {'zone': zone, 'methods': response.data};
                }
                return null;
            })
          );
        }
      }

      // 3. Concurrently fetch all methods.
      final results = await Future.wait(methodFutures);

      // 4. Process the results to find matching and enabled methods.
      for (var result in results) {
        if (result == null) continue;

        final zone = result['zone'];
        final methods = result['methods'];
        final zoneLocations = await _getZoneLocations(zone['id']);

        bool isMatch = _isLocationInZone(zoneLocations, country, state, postcode);

        if (isMatch) {
          for (var methodData in methods) {
            if (methodData['enabled'] == true) {
              // Flexible cost extraction
              final settings = methodData['settings'];
              final costString = settings?['cost']?['value']?.toString();
              final cost = (costString != null && costString.isNotEmpty) 
                            ? double.tryParse(costString) ?? 0.0 
                            : 0.0; // Default to 0.0 for free_shipping etc.

              availableMethods.add(ShippingMethod(
                instanceId: methodData['instance_id'],
                title: methodData['title'],
                methodId: methodData['method_id'],
                cost: cost,
                zoneName: zone['name'] ?? 'N/A',
              ));
            }
          }
        }
      }

       // Also check the "Rest of the World" zone (ID 0)
      final restOfTheWorldMethods = await _getZoneMethods(0);
      if (!_isCountryInAnyZone(allZones, country)) { // only add if country is not in any other zone
          for (var methodData in restOfTheWorldMethods) {
              if (methodData['enabled'] == true) {
                  final settings = methodData['settings'];
                  final costString = settings?['cost']?['value']?.toString();
                  final cost = (costString != null && costString.isNotEmpty) ? double.tryParse(costString) ?? 0.0 : 0.0;

                  availableMethods.add(ShippingMethod(
                      instanceId: methodData['instance_id'],
                      title: methodData['title'],
                      methodId: methodData['method_id'],
                      cost: cost,
                      zoneName: "Rest of the World",
                  ));
              }
          }
      }

      developer.log("Available Shipping Methods: ${availableMethods.map((m) => m.title).toList()}");
      return availableMethods;

    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching shipping methods');
      return [];
    } catch (e, s) {
      developer.log('Unexpected error fetching shipping methods', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<CountryState>> getStatesForCountry(String countryCode) async {
    try {
      final response = await _dio.get(
        '/data/countries/$countryCode',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );

      if (response.statusCode == 200 && response.data['states'] is List) {
        return (response.data['states'] as List)
            .map((s) => CountryState.fromJson(s))
            .toList();
      }
      // If the response is not what we expect, throw a formatted error
      throw 'Failed to fetch states for $countryCode. Status: ${response.statusCode}, Body: ${response.data}';

    } on DioException catch (e) {
      // Re-throw a more informative exception
      throw 'Failed to connect to the server while fetching states for $countryCode. Error: ${e.response?.data ?? e.message}';
    } catch (e) {
      // Re-throw any other exceptions
      throw 'An unexpected error occurred while fetching states: $e';
    }
  }


  // Helper to get locations for a zone
  Future<List<dynamic>> _getZoneLocations(int zoneId) async {
      try {
          final response = await _dio.get(
              '/shipping/zones/$zoneId/locations',
              queryParameters: {
                  'consumer_key': Config.consumerKey,
                  'consumer_secret': Config.consumerSecret,
              },
          );
          return (response.statusCode == 200 && response.data is List) ? response.data : [];
      } catch (e) {
          return [];
      }
  }

  // Helper to get methods for a zone
  Future<List<dynamic>> _getZoneMethods(int zoneId) async {
      try {
          final response = await _dio.get(
            '/shipping/zones/$zoneId/methods',
            queryParameters: {
                'consumer_key': Config.consumerKey,
                'consumer_secret': Config.consumerSecret,
            },
          );
          return (response.statusCode == 200 && response.data is List) ? response.data : [];
      } catch (e) {
          return [];
      }
  }

  // Helper to check if a country is in any of the defined zones
  bool _isCountryInAnyZone(List<dynamic> zones, String countryCode) {
      // This is a simplification. A full implementation requires fetching locations for each zone.
      // For now, we assume if there are zones, the country might be in one.
      // This logic needs to be more robust for a production app.
      return false; // Re-evaluate this logic based on how locations are fetched.
  }

  // Refactored location matching logic
  bool _isLocationInZone(List<dynamic> zoneLocations, String country, String state, String postcode) {
      if (zoneLocations.isEmpty) return false;

      for (var loc in zoneLocations) {
          final type = loc['type'];
          final code = loc['code'];

          switch(type) {
              case 'country':
                  if (code == country) return true;
                  break;
              case 'state':
                  // WooCommerce stores state codes as `COUNTRY:STATE`
                  if (code.contains(':') && code == '$country:$state') return true;
                  break;
              case 'postcode':
                  // Postcode matching can be complex (wildcards, ranges). This is a simple check.
                  if (code == postcode) return true;
                  break;
          }
      }
      return false;
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
