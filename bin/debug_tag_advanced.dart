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
    print('--- Testing tag=638 ---');
    final res1 = await dio.get(
      '/products',
      queryParameters: {...authParams, 'tag': '638'},
    );
    print('tag=638 count: ${res1.data.length}');

    print('--- Testing tags=638 ---');
    final res2 = await dio.get(
      '/products',
      queryParameters: {...authParams, 'tags': '638'},
    );
    print('tags=638 count: ${res2.data.length}');

    print('--- Testing tags=[638] ---');
    final res3 = await dio.get(
      '/products',
      queryParameters: {
        ...authParams,
        'tags': [638],
      },
    );
    print('tags=[638] count: ${res3.data.length}');

    print('--- Testing tag slug "new-arrival" ---');
    final res4 = await dio.get(
      '/products',
      queryParameters: {...authParams, 'tag': 'new-arrival'},
    );
    print('tag slug "new-arrival" count: ${res4.data.length}');
  } catch (e) {
    print('Error: $e');
  }
}
