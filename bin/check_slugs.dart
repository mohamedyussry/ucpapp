import 'package:dio/dio.dart';
import 'package:myapp/config.dart';

void main() async {
  final dio = Dio(
    BaseOptions(baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3'),
  );
  final auth = {
    'consumer_key': Config.consumerKey,
    'consumer_secret': Config.consumerSecret,
  };

  try {
    print('--- Categories ---');
    final cats = await dio.get(
      '/products/categories',
      queryParameters: {...auth, 'per_page': 100},
    );
    for (var c in cats.data) {
      if (c['slug'].toString().contains('new')) {
        print('Category: ${c['name']} | ID: ${c['id']} | Slug: ${c['slug']}');
      }
    }

    print('\n--- Tags ---');
    final tags = await dio.get(
      '/products/tags',
      queryParameters: {...auth, 'per_page': 100},
    );
    for (var t in tags.data) {
      if (t['slug'].toString().contains('new')) {
        print('Tag: ${t['name']} | ID: ${t['id']} | Slug: ${t['slug']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
