import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class TamaraService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Config.tamaraBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Config.tamaraMerchantToken}',
      },
    ),
  );

  /// Create a checkout session with Tamara
  Future<Map<String, dynamic>?> createCheckout({
    required double amount,
    required String currency,
    required Map<String, String> billingData,
    required List<Map<String, dynamic>> items,
    double shippingAmount = 0.0,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
  }) async {
    try {
      final orderReferenceId = 'UCP${DateTime.now().millisecondsSinceEpoch}';
      final baseUrl = Config.wooCommerceUrl;

      final payload = {
        'order_reference_id': orderReferenceId,
        'total_amount': {
          'amount': double.parse(amount.toStringAsFixed(2)),
          'currency': currency,
        },
        'shipping_amount': {
          'amount': double.parse(shippingAmount.toStringAsFixed(2)),
          'currency': currency,
        },
        'tax_amount': {
          'amount': double.parse(taxAmount.toStringAsFixed(2)),
          'currency': currency,
        },
        'discount_amount': {
          'amount': double.parse(discountAmount.toStringAsFixed(2)),
          'currency': currency,
        },
        'description': 'Purchase from UCP Pharmacy',
        'country_code': 'SA',
        // 'payment_type': 'PAY_BY_INSTALMENTS', // Omit to show all available types
        'locale': 'ar_SA',
        'merchant_url': {
          'success': '$baseUrl/tamara/success',
          'failure': '$baseUrl/tamara/failure',
          'cancel': '$baseUrl/tamara/cancel',
          'notification': '$baseUrl/tamara/notification',
        },
        'shipping_address': {
          'first_name': billingData['firstName'] ?? 'Customer',
          'last_name': billingData['lastName'] ?? '.',
          'line1': billingData['address'] ?? 'Street',
          'city': billingData['city'] ?? 'Riyadh',
          'country_code': 'SA',
          'phone_number': _formatPhoneNumber(billingData['phone'] ?? ''),
        },
        'billing_address': {
          'first_name': billingData['firstName'] ?? 'Customer',
          'last_name': billingData['lastName'] ?? '.',
          'line1': billingData['address'] ?? 'Street',
          'city': billingData['city'] ?? 'Riyadh',
          'country_code': 'SA',
          'phone_number': _formatPhoneNumber(billingData['phone'] ?? ''),
        },
        'consumer': {
          'first_name': billingData['firstName'] ?? 'Customer',
          'last_name': billingData['lastName'] ?? '.',
          'phone_number': _formatPhoneNumber(billingData['phone'] ?? ''),
          'email':
              (billingData['email'] != null &&
                  billingData['email']!.trim().isNotEmpty)
              ? billingData['email']!
              : 'customer@ucpapp.com',
        },
        'items': items.map((item) {
          final price =
              double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
          final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

          return {
            'reference_id': item['product_id'].toString(),
            'type': 'Physical',
            'name': item['name'] ?? 'Product',
            'sku': item['sku'] ?? item['product_id'].toString(),
            'quantity': qty,
            'total_amount': {
              'amount': double.parse((price * qty).toStringAsFixed(2)),
              'currency': currency,
            },
          };
        }).toList(),
      };

      developer.log(
        'TAMARA: Creating checkout with payload: ${jsonEncode(payload)}',
      );

      // Tamara V2 uses /checkout, V3 uses /checkouts
      // We'll try /checkout first as it's common.
      final response = await _dio.post('/checkout', data: payload);

      developer.log('TAMARA: Checkout Response: ${response.data}');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        developer.log('TAMARA: Checkout Dio Error');
        developer.log('TAMARA: Status Code: ${e.response?.statusCode}');
        developer.log('TAMARA: Response Data: ${e.response?.data}');
      } else {
        developer.log('TAMARA: Checkout Error', error: e);
      }
      return null;
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '966500000000';

    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // If it starts with 05, replace with 9665
    if (cleaned.startsWith('05') && cleaned.length == 10) {
      cleaned = '966' + cleaned.substring(1);
    }
    // If it starts with 5 and is 9 digits, add 966
    else if (cleaned.startsWith('5') && cleaned.length == 9) {
      cleaned = '966' + cleaned;
    }
    // If it doesn't start with 966, try to make it work
    else if (!cleaned.startsWith('966')) {
      if (cleaned.length <= 9) {
        cleaned = '966' + cleaned;
      }
    }

    return cleaned;
  }
}
