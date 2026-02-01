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
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ),
    );
    _wooCommerceService = WooCommerceService();
  }

  Future<Customer?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/wp-json/jwt-auth/v1/token',
        data: {'username': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        developer.log('Login Response: ${response.data}');
        final token = response.data['token'];

        if (token != null) {
          // Decode the token to get the user ID
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          developer.log('Decoded Token: $decodedToken');

          var userIdValue =
              decodedToken['data']?['user']?['id'] ??
              decodedToken['id'] ??
              decodedToken['sub'];

          if (userIdValue == null) {
            developer.log('User ID not found inside the JWT token.');
            return null;
          }

          final int userId = userIdValue is int
              ? userIdValue
              : int.parse(userIdValue.toString());

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setInt('user_id', userId);

          developer.log(
            'Login successful, fetching customer details for user ID: $userId',
          );

          // Fetch customer details immediately after login
          final customer = await _wooCommerceService.getCustomerById(userId);
          return customer;
        } else {
          developer.log('Login successful but token is missing.');
          return null;
        }
      } else {
        developer.log(
          'Login failed: Status ${response.statusCode}, Body: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e) {
      developer.log(
        'DioException during login: ${e.response?.data?['message'] ?? 'Unknown Dio error'}',
        error: e,
      );
      String errorMessage = 'Login failed.';
      if (e.response != null && e.response?.data != null) {
        if (e.response!.data is Map &&
            e.response!.data.containsKey('message')) {
          errorMessage = e.response!.data['message'].toString();
        } else {
          errorMessage = 'Server error: ${e.response?.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your internet.';
      } else {
        errorMessage = 'Network error. Please try again later.';
      }
      throw errorMessage;
    } catch (e) {
      developer.log('An unexpected error occurred during login: $e');
      throw 'An unexpected error occurred.';
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await _wooCommerceService.createCustomer(
        email,
        password,
        firstName,
        lastName,
        phone: phone,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendSms(
    String phoneNumber,
    String message,
  ) async {
    try {
      final dio = Dio();
      // Using the specific API provided by the user
      final response = await dio.get(
        'https://api.goinfinito.me/unified/v2/send',
        queryParameters: {
          'clientid': 'ucp060zhrbh2xr3dmquctaha',
          'clientpassword': 'pyhy27bfriq848t16xyecx6fztyaei1h',
          'to': phoneNumber,
          'from': 'UCPPharmacy',
          'text': message,
        },
      );

      // Return full response data for debugging
      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('SMS API Success Payload: ${response.data}');

        final String responseBody = response.data.toString();
        // Check if the text response contains "statustext=Success"
        // The API returns a string like: guid=...&statustext=Success
        final bool isSuccess = responseBody.contains('statustext=Success');

        if (isSuccess) {
          return {'success': true, 'message': responseBody};
        } else {
          return {'success': false, 'message': 'API Error: $responseBody'};
        }
      } else {
        developer.log(
          'Failed to send SMS: ${response.statusCode}, ${response.data}',
        );
        return {
          'success': false,
          'message': 'Server Error (${response.statusCode}): ${response.data}',
        };
      }
    } on DioException catch (e) {
      developer.log('DioError sending SMS', error: e);
      return {
        'success': false,
        'message':
            'Connection Error: ${e.response?.statusCode ?? "Unknown"} - ${e.response?.data ?? e.message}',
      };
    } catch (e) {
      developer.log('Error sending SMS', error: e);
      return {'success': false, 'message': 'Unexpected Error: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    developer.log('User logged out and session cleared.');
  }
}
