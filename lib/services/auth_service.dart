
import 'package:dio/dio.dart';
import 'package:myapp/config.dart';
import 'dart:developer' as developer;
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  late final Dio _dio;
  late final WooCommerceService _wooCommerceService;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.wooCommerceUrl,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    _wooCommerceService = WooCommerceService();
  }

  Future<Customer?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/wp-json/jwt-auth/v1/token',
        data: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];

        if (token != null) {
          // Decode the token to get the user ID
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          final userIdString = decodedToken['data']?['user']?['id'];
          
          if (userIdString == null) {
            developer.log('User ID not found inside the JWT token.');
            return null;
          }
          
          final int userId = int.parse(userIdString);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setInt('user_id', userId);

          developer.log('Login successful, fetching customer details for user ID: $userId');

          // Fetch customer details immediately after login
          final customer = await _wooCommerceService.getCustomerById(userId);
          return customer;
        } else {
          developer.log('Login successful but token is missing.');
          return null;
        }
      } else {
        developer.log(
            'Login failed: Status ${response.statusCode}, Body: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      // When login fails (e.g., wrong credentials), the server returns an error code.
      // Instead of throwing an exception, we log it and return null.
      developer.log(
        'DioException during login: ${e.response?.data?['message'] ?? 'Unknown Dio error'}',
        error: e,
      );
      return null; // The login failed, so we return null.
    } catch (e) {
      // For any other unexpected errors, we log them and return null.
      developer.log('An unexpected error occurred during login: $e');
      return null;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _wooCommerceService.createCustomer(
          email, password, firstName, lastName);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    developer.log('User logged out and session cleared.');
  }
}
