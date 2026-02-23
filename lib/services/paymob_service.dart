import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'dart:developer' as developer;

class PaymobService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ksa.paymob.com',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${Config.paymobSecretKey}',
      },
    ),
  );

  /// --- New Intention API ---

  /// Step 1: Create Intention
  /// هذا الطلب يحل محل Auth + Order + Payment Key في النظام القديم
  Future<Map<String, dynamic>?> createIntention({
    required double amount,
    required String currency,
    required Map<String, String> billingData,
    List<int> paymentMethods = const [], // Integration IDs
    List<Map<String, dynamic>> items = const [],
  }) async {
    try {
      // Ensure there is at least one item as required by Paymob Intention API
      final List<Map<String, dynamic>> finalItems = items.isNotEmpty
          ? items
          : [
              {
                'name': 'Order Payment',
                'amount': (amount * 100).toInt(),
                'description': 'Purchase from UCP App',
                'quantity': 1,
              },
            ];

      final requestData = {
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'payment_methods': paymentMethods.isNotEmpty
            ? paymentMethods
            : [Config.paymobIntegrationId, Config.paymobApplePayIntegrationId],
        'items': finalItems,
        'billing_data': {
          'first_name': billingData['firstName'] ?? 'NA',
          'last_name': billingData['lastName'] ?? 'NA',
          'phone_number': billingData['phone'] ?? 'NA',
          'email': billingData['email'] ?? 'customer@ucpapp.com',
          'country': 'SA',
          'state': billingData['state'] ?? 'NA',
          'city': billingData['city'] ?? 'Riyadh',
          'street': billingData['address'] ?? 'Street',
          'building': 'NA',
          'apartment': 'NA',
          'floor': 'NA',
        },
        'customer': {
          'first_name': billingData['firstName'] ?? 'Customer',
          'last_name': billingData['lastName'] ?? 'NA',
          'email': billingData['email'] ?? 'customer@ucpapp.com',
        },
        'redirection_url': 'https://ucpksa.com/payment-success',
      };

      developer.log('PAYMOB: Requesting Intention with: $requestData');

      final response = await _dio.post('/v1/intention/', data: requestData);

      developer.log('PAYMOB: Intention Response: ${response.data}');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        developer.log(
          'PAYMOB INTENTION ERROR: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }
      developer.log('PAYMOB: Create Intention Error', error: e);
      return null;
    }
  }

  /// --- Apple Pay Flash Flow (Post Pay) ---

  /// Flash Flow: Process Apple Pay Payment using Intention ID
  Future<Map<String, dynamic>?> processApplePayPayment({
    required String intentionId,
    required Map<String, dynamic> applePayToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/acceptance/post_pay',
        data: {
          'source': {
            'identifier': 'APPLE_PAY',
            'subtype': 'APPLE_PAY',
            'data': applePayToken['token'],
          },
          'payment_token': intentionId,
        },
      );
      return response.data;
    } catch (e) {
      developer.log('PAYMOB: Apple Pay Process Error', error: e);
      return null;
    }
  }

  /// Full Apple Pay Flow with Intention API
  Future<Map<String, dynamic>?> initiateApplePayPayment({
    required double amount,
    required String currency,
    required Map<String, String> billingData,
    required Map<String, dynamic> applePayToken,
  }) async {
    // 1. إنشاء Intention مخصص لـ Apple Pay
    final intention = await createIntention(
      amount: amount,
      currency: currency,
      billingData: billingData,
      paymentMethods: [Config.paymobApplePayIntegrationId],
    );

    if (intention == null ||
        intention['payment_keys'] == null ||
        (intention['payment_keys'] as List).isEmpty) {
      developer.log('PAYMOB: Apple Pay Intention failed or no payment_keys');
      return null;
    }

    // 2. الحصول على الـ Token الخاص بـ Apple Pay من الاستجابة
    final paymentToken = intention['payment_keys'][0]['token'];

    // 3. إكمال الدفع عبر Flash Flow
    return await processApplePayPayment(
      intentionId: paymentToken,
      applePayToken: applePayToken,
    );
  }

  /// --- Unified Checkout Support ---

  /// الحصول على client_secret للتعامل مع Unified Checkout
  Future<String?> getPaymentToken({
    required double amount,
    required String currency,
    required Map<String, String> billingData,
  }) async {
    final intention = await createIntention(
      amount: amount,
      currency: currency,
      billingData: billingData,
      paymentMethods: [Config.paymobIntegrationId],
    );

    if (intention == null || intention['client_secret'] == null) {
      developer.log('PAYMOB: Failed to get client_secret from intention');
      return null;
    }

    // نرجع الـ client_secret لاستخدامه في الـ Unified Checkout URL
    return intention['client_secret'];
  }
}
