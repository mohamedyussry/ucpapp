import 'package:dio/dio.dart';
import 'package:myapp/config.dart';

void main() async {
  final dio = Dio(
    BaseOptions(baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3'),
  );

  try {
    print('Testing Tag ID: 638...');
    final response = await dio.get(
      '/products',
      queryParameters: {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'tag': '638',
        'per_page': 5,
      },
    );

    if (response.statusCode == 200) {
      final products = response.data as List;
      print('Found ${products.length} products for Tag 638');
      for (var p in products) {
        print(' - ${p['name']}');
      }

      if (products.isEmpty) {
        print('Checking if tag 638 exists...');
        final tagResponse = await dio.get(
          '/products/tags/638',
          queryParameters: {
            'consumer_key': Config.consumerKey,
            'consumer_secret': Config.consumerSecret,
          },
        );
        print('Tag info: ${tagResponse.data}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
