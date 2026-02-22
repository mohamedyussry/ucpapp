import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class TabbyService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Config.tabbyBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Config.tabbyPublicKey}',
      },
    ),
  );

  /// Create a checkout session with Tabby
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
      final baseUrl = Config.wooCommerceUrl;

      final payload = {
        'payment': {
          'amount': amount.toStringAsFixed(2),
          'currency': currency,
          'description': 'Purchase from UCP Pharmacy',
          'buyer': {
            'phone': _formatPhoneNumber(billingData['phone'] ?? ''),
            'email':
                (billingData['email'] != null &&
                    billingData['email']!.trim().isNotEmpty)
                ? billingData['email']!
                : 'customer@ucpapp.com',
            'name':
                '${billingData['firstName'] ?? 'Customer'} ${billingData['lastName'] ?? '.'}',
          },
          'shipping_address': {
            'city': billingData['city'] ?? 'Riyadh',
            'address': billingData['address'] ?? 'Street',
            'zip': billingData['postcode'] ?? '12345',
          },
          'order': {
            'tax_amount': taxAmount.toStringAsFixed(2),
            'shipping_amount': shippingAmount.toStringAsFixed(2),
            'discount_amount': discountAmount.toStringAsFixed(2),
            'items': items.map((item) {
              final price =
                  double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
              final qty =
                  int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
              return {
                'title': item['name'] ?? 'Product',
                'quantity': qty,
                'unit_price': price.toStringAsFixed(2),
                'reference_id': item['product_id'].toString(),
              };
            }).toList(),
          },
        },
        'lang': 'ar',
        'merchant_code':
            'SA', // This might need to be specific to your Tabby account
        'merchant_urls': {
          'success': '$baseUrl/tabby/success',
          'cancel': '$baseUrl/tabby/cancel',
          'failure': '$baseUrl/tabby/failure',
        },
      };

      developer.log(
        'TABBY: Creating checkout with payload: ${jsonEncode(payload)}',
      );

      final response = await _dio.post('/checkout', data: payload);

      developer.log('TABBY: Checkout Response: ${response.data}');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        developer.log('TABBY: Checkout Dio Error');
        developer.log('TABBY: Status Code: ${e.response?.statusCode}');
        developer.log('TABBY: Response Data: ${e.response?.data}');
      } else {
        developer.log('TABBY: Checkout Error', error: e);
      }
      return null;
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '966500000000';
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('05') && cleaned.length == 10) {
      cleaned = '966' + cleaned.substring(1);
    } else if (cleaned.startsWith('5') && cleaned.length == 9) {
      cleaned = '966' + cleaned;
    } else if (!cleaned.startsWith('966')) {
      if (cleaned.length <= 9) {
        cleaned = '966' + cleaned;
      }
    }
    return cleaned;
  }
}
