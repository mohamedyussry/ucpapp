import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:myapp/models/coupon_model.dart';
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/models/payment_method_model.dart';
import 'package:myapp/models/shipping_method_model.dart';
import 'package:myapp/models/state_model.dart';
import '../config.dart';
import '../models/order_payload_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class WooCommerceService {
  late final Dio _dio;

  WooCommerceService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ),
    );
  }

  Future<Coupon?> validateCoupon(String code) async {
    try {
      final response = await _dio.get(
        '/coupons',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'code': code,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          return Coupon.fromJson(data.first);
        } else {
          return null;
        }
      } else {
        developer.log(
          'Error validating coupon: Status ${response.statusCode}, Body: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'validating coupon');
      return null;
    } catch (e, s) {
      developer.log(
        'Unexpected error validating coupon',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<bool> createCustomer(
    String email,
    String password,
    String firstName,
    String lastName, {
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'username': email,
      };

      if (phone != null) {
        data['billing'] = {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'email': email,
        };
      }

      final response = await _dio.post(
        '/customers',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
        data: data,
      );

      if (response.statusCode == 201) {
        developer.log('Registration successful for email: $email');
        return true;
      } else {
        developer.log(
          'Registration failed: Status ${response.statusCode}, Body: ${response.data}',
        );
        return false;
      }
    } on DioException catch (e) {
      developer.log(
        'Error during registration: ${e.response?.data?['message'] ?? 'Unknown error'}',
        error: e,
      );
      throw e.response?.data?['message'] ??
          'An unknown error occurred during registration.';
    } catch (e) {
      developer.log(
        'An unexpected error occurred during registration',
        error: e,
      );
      throw 'An unexpected error occurred.';
    }
  }

  Future<Customer?> getCustomerById(int id) async {
    try {
      final response = await _dio.get(
        '/customers/$id',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        developer.log("CUSTOMER DATA FROM SERVER: ${response.data}");
        return Customer.fromJson(response.data);
      } else {
        developer.log(
          'Error fetching customer: Status ${response.statusCode}, Body: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching customer');
      return null;
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching customer',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<Customer?> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '/customers/$id',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
        data: data,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        developer.log("CUSTOMER UPDATED ON SERVER: ${response.data}");
        return Customer.fromJson(response.data);
      } else {
        developer.log(
          'Error updating customer: Status ${response.statusCode}, Body: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'updating customer');
      return null;
    } catch (e, s) {
      developer.log(
        'Unexpected error updating customer',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<bool> updateCustomerMeta(
    int customerId,
    List<Map<String, dynamic>> metaData,
  ) async {
    try {
      developer.log(
        'Updating customer meta for ID: $customerId with data: $metaData',
      );
      final response = await _dio.put(
        '/customers/$customerId',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
        data: {'meta_data': metaData},
      );

      if (response.statusCode == 200) {
        developer.log('Customer meta updated successfully for ID: $customerId');
        return true;
      } else {
        developer.log(
          'Failed to update customer meta: Status ${response.statusCode}, Body: ${response.data}',
        );
        return false;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'updating customer meta');
      return false;
    } catch (e, s) {
      developer.log(
        'Unexpected error updating customer meta',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// New Direct Method for FCM Token
  Future<bool> updateFcmToken(int userId, String token) async {
    try {
      final String fullUrl =
          '${Config.wooCommerceUrl}/wp-json/ucp/v1/update-fcm-token';
      developer.log('Direct FCM Update: URL: $fullUrl, User #$userId');

      // Use a fresh Dio instance to avoid baseUrl conflicts
      final syncDio = Dio();
      final response = await syncDio.post(
        fullUrl,
        data: {'user_id': userId, 'fcm_token': token},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => true, // Accept all statuses for debugging
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        developer.log(
          'Direct FCM Update FAILED: Status ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      developer.log(
        'Direct FCM Update DIO ERROR: ${e.message}, Body: ${e.response?.data}',
      );
      return false;
    } catch (e) {
      developer.log('Direct FCM Update EXCEPTION: $e');
      return false;
    }
  }

  Future<Order?> getOrderById(int id) async {
    try {
      final response = await _dio.get(
        '/orders/$id',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Order.fromJson(response.data);
      } else {
        developer.log(
          'Error fetching order by ID: Status ${response.statusCode}, Body: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching order by ID');
      return null;
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching order by ID',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<List<Customer>> getCustomers({String? search}) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'role': 'all',
      };

      if (search != null) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/customers',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) => Customer.fromJson(c))
            .toList();
      } else {
        developer.log(
          'Error searching customers: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'searching customers');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error searching customers',
        error: e,
        stackTrace: s,
      );
      return [];
    }
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
          'Error creating order: Status ${response.statusCode}, Body: ${response.data}',
        );
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

  // Combined method to get orders either by customer ID or a list of order IDs.
  Future<List<Map<String, dynamic>>> getOrders({
    int? customerId,
    List<int>? orderIds,
  }) async {
    try {
      developer.log(
        'Fetching orders for customer: $customerId, orderIds: $orderIds',
      );

      if (customerId == null && (orderIds == null || orderIds.isEmpty)) {
        developer.log(
          'Either customerId or a non-empty list of orderIds must be provided.',
        );
        return [];
      }

      final Map<String, dynamic> queryParameters = {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'per_page': 100,
      };

      if (customerId != null) {
        queryParameters['customer'] = customerId;
      } else if (orderIds != null && orderIds.isNotEmpty) {
        queryParameters['include'] = orderIds.join(',');
      }

      final response = await _dio.get(
        '/orders',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        developer.log('Successfully fetched ${data.length} orders');
        return List<Map<String, dynamic>>.from(data);
      } else {
        developer.log(
          'Error fetching orders: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching orders');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching orders',
        error: e,
        stackTrace: s,
      );
      return [];
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
            .where((p) => p.enabled)
            .toList();
      } else {
        developer.log(
          'Error fetching payment methods: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching payment methods');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching payment methods',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<List<WooProduct>> getProducts({
    int? categoryId,
    int? brandId,
    bool? featured,
    String? orderby,
    String? order,
    List<int>? include,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'per_page': 100,
        'status': 'publish',
      };

      if (categoryId != null) {
        queryParameters['category'] = categoryId.toString();
      }

      if (brandId != null) {
        queryParameters['brand'] = brandId.toString();
      }

      if (featured == true) {
        queryParameters['featured'] = true;
      }

      if (orderby != null) {
        queryParameters['orderby'] = orderby;
      }

      if (order != null) {
        queryParameters['order'] = order;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (include != null && include.isNotEmpty) {
        queryParameters['include'] = include.join(',');
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
          'Error fetching products: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching products');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching products',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<List<WooBrand>> getBrands() async {
    try {
      final response = await _dio.get(
        '/products/brands',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
          'per_page': 100,
          'hide_empty': true,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((b) => WooBrand.fromJson(b))
            .toList();
      } else {
        developer.log(
          'Error fetching brands: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching brands');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching brands',
        error: e,
        stackTrace: s,
      );
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
          'Error fetching product variations: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching product variations');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching product variations',
        error: e,
        stackTrace: s,
      );
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
          'Error fetching categories: Status ${response.statusCode}, Body: ${response.data}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching categories');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching categories',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<List<ShippingMethod>> getShippingMethodsForLocation(
    String country,
    String state,
    String postcode,
  ) async {
    try {
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

      List<Future> methodFutures = [];

      for (var zone in allZones) {
        final zoneId = zone['id'];
        if (zoneId != null) {
          methodFutures.add(
            _dio
                .get(
                  '/shipping/zones/$zoneId/methods',
                  queryParameters: {
                    'consumer_key': Config.consumerKey,
                    'consumer_secret': Config.consumerSecret,
                  },
                )
                .then((response) {
                  if (response.statusCode == 200 && response.data is List) {
                    return {'zone': zone, 'methods': response.data};
                  }
                  return null;
                }),
          );
        }
      }

      final results = await Future.wait(methodFutures);

      for (var result in results) {
        if (result == null) continue;

        final zone = result['zone'];
        final methods = result['methods'];
        final zoneLocations = await _getZoneLocations(zone['id']);

        bool isMatch = _isLocationInZone(
          zoneLocations,
          country,
          state,
          postcode,
        );

        if (isMatch) {
          for (var methodData in methods) {
            if (methodData['enabled'] == true) {
              final settings = methodData['settings'];
              final costString = settings?['cost']?['value']?.toString();
              final cost = (costString != null && costString.isNotEmpty)
                  ? double.tryParse(costString) ?? 0.0
                  : 0.0;

              availableMethods.add(
                ShippingMethod(
                  instanceId: methodData['instance_id'],
                  title: methodData['title'],
                  methodId: methodData['method_id'],
                  cost: cost,
                  zoneName: zone['name'] ?? 'N/A',
                ),
              );
            }
          }
        }
      }

      final restOfTheWorldMethods = await _getZoneMethods(0);
      if (!_isCountryInAnyZone(allZones, country)) {
        for (var methodData in restOfTheWorldMethods) {
          if (methodData['enabled'] == true) {
            final settings = methodData['settings'];
            final costString = settings?['cost']?['value']?.toString();
            final cost = (costString != null && costString.isNotEmpty)
                ? double.tryParse(costString) ?? 0.0
                : 0.0;

            availableMethods.add(
              ShippingMethod(
                instanceId: methodData['instance_id'],
                title: methodData['title'],
                methodId: methodData['method_id'],
                cost: cost,
                zoneName: "Rest of the World",
              ),
            );
          }
        }
      }

      developer.log(
        "Available Shipping Methods: ${availableMethods.map((m) => m.title).toList()}",
      );
      return availableMethods;
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching shipping methods');
      return [];
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching shipping methods',
        error: e,
        stackTrace: s,
      );
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
      throw 'Failed to fetch states for $countryCode. Status: ${response.statusCode}, Body: ${response.data}';
    } on DioException catch (e) {
      throw 'Failed to connect to the server while fetching states for $countryCode. Error: ${e.response?.data ?? e.message}';
    } catch (e) {
      throw 'An unexpected error occurred while fetching states: $e';
    }
  }

  Future<List<dynamic>> _getZoneLocations(int zoneId) async {
    try {
      final response = await _dio.get(
        '/shipping/zones/$zoneId/locations',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );
      return (response.statusCode == 200 && response.data is List)
          ? response.data
          : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getZoneMethods(int zoneId) async {
    try {
      final response = await _dio.get(
        '/shipping/zones/$zoneId/methods',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );
      return (response.statusCode == 200 && response.data is List)
          ? response.data
          : [];
    } catch (e) {
      return [];
    }
  }

  bool _isCountryInAnyZone(List<dynamic> zones, String countryCode) {
    return false;
  }

  bool _isLocationInZone(
    List<dynamic> zoneLocations,
    String country,
    String state,
    String postcode,
  ) {
    if (zoneLocations.isEmpty) return false;

    for (var loc in zoneLocations) {
      final type = loc['type'];
      final code = loc['code'];

      switch (type) {
        case 'country':
          if (code == country) return true;
          break;
        case 'state':
          if (code.contains(':') && code == '$country:$state') return true;
          break;
        case 'postcode':
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
        return response.data['symbol'] as String;
      } else {
        developer.log(
          'Error fetching currency symbol: Status ${response.statusCode}, Body: ${response.data}',
        );
        return '';
      }
    } on DioException catch (e, s) {
      _handleDioError(e, s, 'fetching currency symbol');
      return '';
    } catch (e, s) {
      developer.log(
        'Unexpected error fetching currency symbol',
        error: e,
        stackTrace: s,
      );
      return '';
    }
  }

  void _handleDioError(DioException e, StackTrace s, String context) {
    if (e.response != null) {
      developer.log(
        'Error $context: Status ${e.response?.statusCode}, Body: ${e.response?.data}',
        error: e,
        stackTrace: s,
      );
    } else {
      developer.log(
        'Error $context: The connection errored. This might be a network issue or a server-side problem like CORS or bot protection.',
        error: e,
        stackTrace: s,
      );
      developer.log('Dio message: ${e.message}');
    }
  }
}
