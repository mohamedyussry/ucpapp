import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';
import '../services/notification_service.dart';
import 'package:sms_autofill/sms_autofill.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _wooCommerceService = WooCommerceService();
  AuthStatus _status = AuthStatus.uninitialized;
  Customer? _customer;
  String? loginErrorMessage;

  // OTP related state
  String? _generatedOtp;
  String? _phoneForVerification;
  bool _isOtpSent = false;
  String _debugLog = 'Waiting for action...'; // New debug variable

  AuthStatus get status => _status;
  Customer? get customer => _customer;
  bool get isOtpSent => _isOtpSent;
  String get debugLog => _debugLog; // Getter
  String? get generatedOtp => _generatedOtp; // Getter for testing auto-fill

  AuthProvider() {
    initAuth();
  }

  // Generate a random 4-digit OTP
  String _generateOtp() {
    var rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    // _status = AuthStatus.uninitialized; // REMOVED: Caused widget unmount
    _debugLog = 'Sending request via API...'; // Reset log
    // notifyListeners(); // REMOVED: Do not trigger global rebuild yet

    try {
      final otp = _generateOtp();
      _generatedOtp = otp;
      _phoneForVerification = phoneNumber;

      developer.log('Generated OTP for $phoneNumber: $otp');

      // Reverting to the required template by the provider
      final signature = await SmsAutoFill().getAppSignature;
      developer.log('Fetched Signature: "$signature"');

      // Construct the message carefully to match the approved template.
      // On iOS, signature is usually empty. If we add \n$signature, we get a trailing newline.
      String message = 'OTP Code : $otp\nحياك الله فى عائلة UCP';

      if (signature.isNotEmpty) {
        message += '\n$signature';
      }

      developer.log('Sending message: "$message"');

      // sendSms now returns a Map {success, message}
      final result = await _authService.sendSms(phoneNumber, message);

      // Update the debug log with the full server response
      _debugLog = result['message'];

      if (result['success'] == true) {
        // Success
        _isOtpSent = true;
        _status = AuthStatus.unauthenticated;
        loginErrorMessage = null;
        notifyListeners();
        return true;
      } else {
        // Failure
        loginErrorMessage = result['message'];
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      developer.log('Error sending OTP', error: e);
      _debugLog = "Exception: $e";
      loginErrorMessage = "An unexpected error occurred: $e";
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Verifies the OTP and checks if the user exists in WooCommerce.
  /// Returns:
  /// - 1: Login successful (User found)
  /// - 2: OTP valid, but user not found (Needs registration)
  /// - 0: Invalid OTP or error
  Future<int> verifyOtp(String inputCode) async {
    if (_generatedOtp == null || _generatedOtp != inputCode) {
      loginErrorMessage = "Invalid verification code.";
      notifyListeners();
      return 0;
    }

    // OTP is correct
    try {
      _status = AuthStatus.uninitialized; // Loading
      notifyListeners();

      // Search for user by phone
      final customers = await _wooCommerceService.getCustomers(
        search: _phoneForVerification,
      );

      // Filter strictly by phone if search is broad, or just take the first match if appropriate
      // Note: WooCommerce search might return matches on email too, so be careful.
      // We'll assume if we find a customer with this phone in billing/shipping, it's them.
      // Since 'search' parameter searches multiple fields, let's pick the first one.

      if (customers.isNotEmpty) {
        // Log them in
        _customer = customers.first;
        _status = AuthStatus.authenticated;

        // Save session (Simulated login since we don't have JWT)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', _customer!.id);
        // We can't save JWT here, so some features requiring strict auth might fail
        // unless we use a "Social Login" plugin mechanism on backend.

        developer.log('OTP Login successful for user: ${_customer!.email}');
        _registerFcmToken();
        notifyListeners();
        return 1;
      } else {
        // User not found, attempt AUTO REGISTRATION
        developer.log(
          'User not found. Attempting auto-registration for $_phoneForVerification',
        );

        // Generate placeholder data
        // Cleaning phone for email usage
        final String cleanPhone = _phoneForVerification!.replaceAll(
          RegExp(r'\D'),
          '',
        );
        final String autoEmail = 'u$cleanPhone@ucppharmacy.com';
        final String autoPass =
            'Pass$cleanPhone!'; // Simple but meets lengthreq usually
        final String autoName = 'Guest User';
        final String autoLastName = '';

        bool regSuccess = await register(
          email: autoEmail,
          password: autoPass,
          firstName: autoName,
          lastName: autoLastName,
          phone: _phoneForVerification,
        );

        if (regSuccess) {
          developer.log(
            'Auto-registration success. Attempting to fetch and login...',
          );
          // Try fetching again to get the ID and object
          // Note: Depending on backend latency, it might take a moment, but usually instant.
          // We might need to implement a retry or use login method.
          // Since we have email/pass, we can actually call login()!
          bool loginSuccess = await login(autoEmail, autoPass);
          if (loginSuccess) {
            return 1; // Success
          }
        }

        loginErrorMessage = "Failed to complete automatic registration.";
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return 0; // Failure
      }
    } catch (e) {
      developer.log('Error during OTP verification flow', error: e);
      loginErrorMessage = "An error occurred checking user data.";
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return 0;
    }
  }

  Future<void> initAuth() async {
    developer.log('AuthProvider: Initializing...');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    // If we have a userId, we can attempt to fetch the customer.
    if (userId != null) {
      developer.log('AuthProvider: Found stored user ID: $userId');
      try {
        final customer = await _wooCommerceService.getCustomerById(userId);
        if (customer != null) {
          _customer = customer;
          _status = AuthStatus.authenticated;
          _registerFcmToken();
          developer.log('AuthProvider: User is authenticated (ID: $userId).');
        } else {
          _status = AuthStatus.unauthenticated;
          await _authService.logout();
          developer.log(
            'AuthProvider: User ID found but customer fetch failed. Logging out.',
          );
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        await _authService.logout();
        developer.log(
          'AuthProvider: Error during initialization, logging out.',
          error: e,
        );
      }
    } else {
      _status = AuthStatus.unauthenticated;
      developer.log('AuthProvider: No user session found.');
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
        _registerFcmToken();
        loginErrorMessage = null; // Ensure error is cleared on success
        developer.log('AuthProvider: Login successful.');
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        loginErrorMessage = 'User not found or database error.';
        developer.log('AuthProvider: Login failed (null customer).');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      loginErrorMessage = e.toString().replaceFirst('Exception: ', '');
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

  Future<bool> deleteAccount({bool autoLogout = true}) async {
    if (_customer == null) return false;

    try {
      final success = await _wooCommerceService
          .deleteCustomer(_customer!.id)
          .timeout(const Duration(seconds: 15), onTimeout: () => false);

      if (success) {
        if (autoLogout) {
          await logout();
        }
        return true;
      }
      return false;
    } catch (e) {
      developer.log('AuthProvider: Error deleting account', error: e);
      return false;
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
      bool success = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      return success;
    } catch (e) {
      developer.log('AuthProvider: Exception during registration.', error: e);
      return false;
    }
  }

  bool _isUpdatingCustomer = false;
  bool get isUpdatingCustomer => _isUpdatingCustomer;

  Future<bool> updateCustomerDetails({
    String? firstName,
    String? lastName,
    String? company,
    String? address1,
    String? address2,
    String? city,
    String? postcode,
    String? country,
    String? state,
    String? phone,
    String? email,
    File? imageFile,
  }) async {
    if (_customer == null) return false;

    _isUpdatingCustomer = true;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {};

      // Top-level fields
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (email != null) updateData['email'] = email;

      // Billing fields
      final Map<String, dynamic> billingData = {};
      if (firstName != null) billingData['first_name'] = firstName;
      if (lastName != null) billingData['last_name'] = lastName;
      if (company != null) billingData['company'] = company;
      if (address1 != null) billingData['address_1'] = address1;
      if (address2 != null) billingData['address_2'] = address2;
      if (city != null) billingData['city'] = city;
      if (postcode != null) billingData['postcode'] = postcode;
      if (country != null) billingData['country'] = country;
      if (state != null) billingData['state'] = state;
      if (phone != null) billingData['phone'] = phone;
      if (email != null) billingData['email'] = email;

      if (billingData.isNotEmpty) {
        updateData['billing'] = billingData;
      }

      // Handle Image Upload
      if (imageFile != null) {
        developer.log('Uploading profile image...');
        final Map<String, dynamic>? imageResponse = await _wooCommerceService
            .uploadImage(imageFile);

        if (imageResponse != null) {
          final String imageUrl = imageResponse['source_url'];
          final int imageId = imageResponse['id'];

          developer.log('Image uploaded. ID: $imageId, URL: $imageUrl');

          // Try multiple ways to save the avatar for maximum compatibility
          updateData['meta_data'] = [
            // Simple Local Avatars (often uses array with full path and media_id)
            {
              'key': 'simple_local_avatar',
              'value': {'full': imageUrl, 'media_id': imageId},
            },
            // Basic User Avatars (often uses meta key 'basic_user_avatar' with array or just ID in some forks)
            {
              'key': 'basic_user_avatar',
              'value': {'full': imageUrl},
            },
            // WP User Avatar / ProfilePress (often uses 'wp_user_avatar' with media ID)
            {'key': 'wp_user_avatar', 'value': imageId},
          ];

          // Also try sending avatar_url at root, just in case custom endpoint supports it
          updateData['avatar_url'] = imageUrl;
        } else {
          developer.log('Profile image upload failed.');
        }
      }

      final updatedCustomer = await _wooCommerceService.updateCustomer(
        _customer!.id,
        updateData,
      );

      if (updatedCustomer != null) {
        _customer = updatedCustomer;

        // If image was uploaded but server didn't return it in avatar_url (read-only),
        // manually set it locally so the UI updates immediately.
        if (imageFile != null && updateData.containsKey('avatar_url')) {
          _customer!.avatarUrl = updateData['avatar_url'];
        }

        _isUpdatingCustomer = false;
        notifyListeners();
        developer.log(
          'AuthProvider: Customer details updated on server and locally.',
        );
        return true;
      }

      _isUpdatingCustomer = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isUpdatingCustomer = false;
      notifyListeners();
      developer.log('AuthProvider: Error updating customer details', error: e);
      return false;
    }
  }

  bool _isSyncingFcm = false;
  bool get isSyncingFcm => _isSyncingFcm;

  Future<bool> syncFcmToken() async {
    if (_customer == null) return false;
    _isSyncingFcm = true;
    notifyListeners();
    try {
      String? token = await NotificationService().getToken();
      if (token != null) {
        bool success = await _wooCommerceService.updateFcmToken(
          _customer!.id,
          token,
        );
        _isSyncingFcm = false;
        notifyListeners();
        return success;
      }
      _isSyncingFcm = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isSyncingFcm = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _registerFcmToken() async {
    if (_customer != null) {
      try {
        await NotificationService().updateTokenOnServer(_customer!.id);
      } catch (e) {
        developer.log('Error registering FCM token', error: e);
      }
    }
  }
}
