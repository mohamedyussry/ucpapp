import 'package:dio/dio.dart';
import 'package:myapp/config.dart';

void main() async {
  final dio = Dio(
    BaseOptions(baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3'),
  );

  final authParams = {
    'consumer_key': Config.consumerKey,
    'consumer_secret': Config.consumerSecret,
  };

  try {
    print('--- Searching for category with slug: new-arrival ---');
    final response = await dio.get(
      '/products/categories',
      queryParameters: {...authParams, 'slug': 'new-arrival'},
    );

    if (response.statusCode == 200) {
      final categories = response.data as List;
      if (categories.isNotEmpty) {
        final cat = categories.first;
        print('Found Category: ${cat['name']}');
        print('ID: ${cat['id']}');
        print('Slug: ${cat['slug']}');
      } else {
        print('No category found with slug: new-arrival');

        print('\n--- Listing first 20 categories to find it ---');
        final allCatsRes = await dio.get(
          '/products/categories',
          queryParameters: {...authParams, 'per_page': 20},
        );
        for (var c in allCatsRes.data) {
          print('Name: ${c['name']} | ID: ${c['id']} | Slug: ${c['slug']}');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
