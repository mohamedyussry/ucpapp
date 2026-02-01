import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'package:myapp/models/loyalty_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LoyaltyService {
  late final Dio _dio;

  LoyaltyService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${Config.wooCommerceUrl}/wp-json/woorewards/v1',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor to include JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<LoyaltyData?> getLoyaltyData() async {
    try {
      final response = await _dio.get('/loyalty');
      if (response.statusCode == 200) {
        return LoyaltyData.fromJson(response.data);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching loyalty data', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await _dio.get('/settings');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      developer.log('Error fetching loyalty settings', error: e);
      return null;
    }
  }

  Future<bool> updatePoints({
    required int userId,
    required int points,
    String operation = 'earn',
    int? orderId,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'points': points,
        'operation': operation,
        if (orderId != null) 'order_id': orderId,
      };
      developer.log('LOYALTY: Updating points with payload: $payload');

      final response = await _dio.post('/update-points', data: payload);

      developer.log(
        'LOYALTY: Update points response: ${response.statusCode} - ${response.data}',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e, s) {
      developer.log('LOYALTY: Error updating points', error: e, stackTrace: s);
      if (e is DioException) {
        developer.log('LOYALTY: Response Data: ${e.response?.data}');
        developer.log('LOYALTY: Response Status: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  Future<List<PointHistory>> getPointHistory() async {
    try {
      final response = await _dio.get('/history');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => PointHistory.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching point history', error: e);
      return [];
    }
  }

  Future<List<LoyaltyTier>> getTiers() async {
    try {
      final response = await _dio.get('/tiers');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => LoyaltyTier.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching loyalty tiers', error: e);
      return [];
    }
  }
}
