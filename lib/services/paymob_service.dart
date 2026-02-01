import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'dart:developer' as developer;

class PaymobService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ksa.paymob.com/api',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Step 1: Authentication Request
  Future<String?> getAuthToken() async {
    try {
      final response = await _dio.post(
        '/auth/tokens',
        data: {'api_key': Config.paymobApiKey},
      );
      return response.data['token'];
    } catch (e) {
      developer.log('PAYMOB: Auth Token Error', error: e);
      return null;
    }
  }

  /// Step 2: Order Registration
  Future<int?> createOrder({
    required String authToken,
    required double amount,
    required String currency,
    List<Map<String, dynamic>> items = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/ecommerce/orders',
        data: {
          'auth_token': authToken,
          'delivery_needed': 'false',
          'amount_cents': (amount * 100).toInt().toString(),
          'currency': currency,
          'items': items,
        },
      );
      return response.data['id'];
    } catch (e) {
      developer.log('PAYMOB: Order Registration Error', error: e);
      return null;
    }
  }

  /// Step 3: Payment Key Request
  Future<String?> getPaymentKey({
    required String authToken,
    required int orderId,
    required double amount,
    required String currency,
    required Map<String, String> billingData,
  }) async {
    try {
      final response = await _dio.post(
        '/acceptance/payment_keys',
        data: {
          'auth_token': authToken,
          'amount_cents': (amount * 100).toInt().toString(),
          'expiration': 3600,
          'order_id': orderId.toString(),
          'billing_data': {
            'apartment': 'NA',
            'email': billingData['email'] ?? 'NA',
            'floor': 'NA',
            'first_name': billingData['firstName'] ?? 'NA',
            'street': billingData['address'] ?? 'NA',
            'building': 'NA',
            'phone_number': billingData['phone'] ?? 'NA',
            'shipping_method': 'PKG',
            'postal_code': 'NA',
            'city': billingData['city'] ?? 'NA',
            'country': 'SA',
            'last_name': billingData['lastName'] ?? 'NA',
            'state': billingData['state'] ?? 'NA',
          },
          'currency': currency,
          'integration_id': Config.paymobIntegrationId,
        },
      );
      return response.data['token'];
    } catch (e) {
      developer.log('PAYMOB: Payment Key Error', error: e);
      return null;
    }
  }

  /// Full Flow to get Payment Token
  Future<String?> getPaymentToken({
    required double amount,
    required String currency,
    required Map<String, String> billingData,
  }) async {
    final authToken = await getAuthToken();
    if (authToken == null) return null;

    final orderId = await createOrder(
      authToken: authToken,
      amount: amount,
      currency: currency,
    );
    if (orderId == null) return null;

    final paymentKey = await getPaymentKey(
      authToken: authToken,
      orderId: orderId,
      amount: amount,
      currency: currency,
      billingData: billingData,
    );
    return paymentKey;
  }
}
