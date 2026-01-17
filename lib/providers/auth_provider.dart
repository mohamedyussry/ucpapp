
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _wooCommerceService = WooCommerceService();
  AuthStatus _status = AuthStatus.uninitialized;
  Customer? _customer;
  String? loginErrorMessage; // Add this line

  AuthStatus get status => _status;
  Customer? get customer => _customer;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    // ... (rest of the method is unchanged)
    developer.log('AuthProvider: Initializing...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = prefs.getInt('user_id');

    if (token != null && userId != null) {
      try {
        final customer = await _wooCommerceService.getCustomerById(userId);
        if (customer != null) {
          _customer = customer;
          _status = AuthStatus.authenticated;
          developer.log('AuthProvider: User is authenticated.');
        } else {
          _status = AuthStatus.unauthenticated;
          await _authService.logout();
          developer.log(
              'AuthProvider: Token found but user data fetch failed. Logging out.');
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        await _authService.logout();
        developer.log('AuthProvider: Error during initialization, logging out.',
            error: e);
      }
    } else {
      _status = AuthStatus.unauthenticated;
      developer.log('AuthProvider: No token found. User is unauthenticated.');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.uninitialized; // Show loading state
    loginErrorMessage = null; // Clear previous error message
    notifyListeners();

    try {
      final customer = await _authService.login(email, password);
      if (customer != null) {
        _customer = customer;
        _status = AuthStatus.authenticated;
        loginErrorMessage = null; // Ensure error is cleared on success
        developer.log('AuthProvider: Login successful.');
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        loginErrorMessage = 'Invalid username or password.'; // Set error message
        developer.log('AuthProvider: Login failed.');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      loginErrorMessage = 'An error occurred. Please try again.'; // Set error message
      developer.log('AuthProvider: Exception during login.', error: e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _customer = null;
    _status = AuthStatus.unauthenticated;
    developer.log('AuthProvider: User logged out.');
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      bool success = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      return success;
    } catch (e) {
      developer.log('AuthProvider: Exception during registration.', error: e);
      return false;
    }
  }

  Future<void> updateCustomerDetails({
    String? firstName,
    String? lastName,
    String? address,
    String? birthday,
    String? gender,
    String? phone,
  }) async {
    if (_customer != null) {
      _customer!.firstName = firstName ?? _customer!.firstName;
      _customer!.lastName = lastName ?? _customer!.lastName;
      _customer!.address = address ?? _customer!.address;
      _customer!.birthday = birthday ?? _customer!.birthday;
      _customer!.gender = gender ?? _customer!.gender;
      _customer!.phone = phone ?? _customer!.phone;
      notifyListeners();
      developer.log('AuthProvider: Customer details updated locally.');
    }
  }
}
