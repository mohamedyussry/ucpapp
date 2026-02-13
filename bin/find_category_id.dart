import 'package:dio/dio.dart';
import 'package:myapp/config.dart';

void main() async {
  final dio = Dio(
    BaseOptions(baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3'),
  );

  try {
    final response = await dio.get(
      '/products/categories',
      queryParameters: {
        'consumer_key': Config.consumerKey,
        'consumer_secret': Config.consumerSecret,
        'per_page': 100,
      },
    );

    if (response.statusCode == 200) {
      final categories = response.data as List;
      for (var cat in categories) {
        print('Category: ${cat['name']} - ID: ${cat['id']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
