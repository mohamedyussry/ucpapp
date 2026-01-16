
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/payment_method_model.dart';
import 'package:myapp/models/shipping_method_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';

// A simple data class for the order
class OrderData {
  int? customerId;
  String? billingFirstName;
  String? billingLastName;
  String? billingEmail;
  String? billingPhone;
  String? billingAddress1;
  String? billingCity;
  String? billingState;
  String? billingPostcode;
  String? billingCountry;
}

class CheckoutProvider with ChangeNotifier {
  final WooCommerceService _wooCommerceService = WooCommerceService();
  final AuthProvider? _authProvider;
  final PageController pageController = PageController();
  final OrderData orderData = OrderData();

  int _currentPage = 0;
  List<CountryState> _states = [];
  String? _selectedStateCode;
  List<ShippingMethod> _shippingMethods = [];
  ShippingMethod? _selectedShippingMethod;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;

  double _subtotal = 0.0;
  double _shippingCost = 0.0;
  final double _tax = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get currentPage => _currentPage;
  List<CountryState> get states => _states;
  String? get selectedStateCode => _selectedStateCode;
  List<ShippingMethod> get shippingMethods => _shippingMethods;
  ShippingMethod? get selectedShippingMethod => _selectedShippingMethod;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  double get subtotal => _subtotal;
  double get shippingCost => _shippingCost;
  double get tax => _tax;
  double get total => _subtotal + _shippingCost + _tax;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CheckoutProvider(this._authProvider) {
    _initializePaymentMethods();
    _autofillUserDetails();
  }

  void reset() {
    _currentPage = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    // Reset other checkout-specific state
    _states = [];
    _selectedStateCode = null;
    _shippingMethods = [];
    _selectedShippingMethod = null;
    _shippingCost = 0.0;
    _errorMessage = null;
    
    // Re-autofill user details in case the user has changed
    _autofillUserDetails();

    notifyListeners();
    developer.log('CheckoutProvider has been reset.');
  }

  void _autofillUserDetails() {
    if (_authProvider != null && _authProvider.status == AuthStatus.authenticated) {
      final user = _authProvider.customer;
      orderData.customerId = user?.id;
      orderData.billingFirstName = user?.firstName;
      orderData.billingLastName = user?.lastName;
      orderData.billingEmail = user?.email;
      developer.log('Autofilled user details for user ID: ${user?.id}');
    } else {
      // Clear details if user is logged out
      orderData.customerId = null;
      orderData.billingFirstName = null;
      orderData.billingLastName = null;
      orderData.billingEmail = null;
    }
    notifyListeners();
  }

  void _initializePaymentMethods() {
    _paymentMethods = [
      PaymentMethod(id: 'cod', title: 'Cash on Delivery', description: 'Pay with cash upon delivery.', enabled: true),
    ];
    _selectedPaymentMethod = _paymentMethods.first;
    notifyListeners();
  }

  void updateSubtotal(double cartTotal) {
    _subtotal = cartTotal;
    notifyListeners();
  }

  Future<void> initializeCheckout(String country, String postcode) async {
    setLoading(true);
    _errorMessage = null;
    developer.log('Initializing checkout...');

    await fetchStates(country);

    if (_errorMessage == null) {
      await Future.wait([
        if (_selectedStateCode != null)
          fetchShippingMethods(country, _selectedStateCode!, postcode),
      ]);
    }

    setLoading(false);
    developer.log('Checkout initialization finished.');
  }

  Future<void> fetchStates(String countryCode) async {
    try {
      final fetchedStates = await _wooCommerceService.getStatesForCountry(countryCode);
      _states = fetchedStates;
      if (_states.isNotEmpty) {
        _selectedStateCode = _states.first.code;
        developer.log('States fetched. Default state: $_selectedStateCode');
      }
    } catch (e) {
      _errorMessage = 'Failed to load regions: ${e.toString()}';
      developer.log(_errorMessage!);
    }
  }

  Future<void> fetchShippingMethods(
      String country, String state, String postcode) async {
    try {
      final methods = await _wooCommerceService.getShippingMethodsForLocation(
          country, state, postcode);
      _shippingMethods = methods;
      if (_shippingMethods.isNotEmpty) {
        _selectedShippingMethod = _shippingMethods.first;
        _shippingCost = _selectedShippingMethod!.cost;
        developer
            .log('Shipping methods fetched. Default: ${_selectedShippingMethod?.title}');
      } else {
        _shippingCost = 0.0;
        developer.log('No shipping methods available for the selected location.');
      }
    } catch (e) {
      _errorMessage = 'Failed to load shipping options: ${e.toString()}';
      developer.log(_errorMessage!);
    }
  }

  void selectState(String stateCode) {
    _selectedStateCode = stateCode;
    orderData.billingState = stateCode;
    developer.log('State selected: $stateCode');
    fetchShippingMethods('SA', stateCode, '');
    notifyListeners();
  }

  void selectShippingMethod(ShippingMethod method) {
    _selectedShippingMethod = method;
    _shippingCost = method.cost;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
