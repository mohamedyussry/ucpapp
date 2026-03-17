import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/payment_method_model.dart';
import 'package:myapp/models/shipping_method_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/config.dart';

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
  double _loyaltyDiscount = 0.0;
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
  double get loyaltyDiscount => _loyaltyDiscount;
  double get total => (_subtotal + _shippingCost + _tax - _loyaltyDiscount)
      .clamp(0.0, double.infinity);
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
    orderData.billingState = null;
    orderData.billingCity = null;
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
    if (_authProvider != null &&
        _authProvider.status == AuthStatus.authenticated) {
      final user = _authProvider.customer;
      orderData.customerId = user?.id;
      developer.log(
        'Set customer ID: ${user?.id} (Autofill of billing details disabled by request)',
      );
    } else {
      // Clear details if user is logged out
      orderData.customerId = null;
      orderData.billingFirstName = null;
      orderData.billingLastName = null;
      orderData.billingEmail = null;
      orderData.billingPhone = null;
      orderData.billingAddress1 = null;
      orderData.billingCity = null;
      orderData.billingState = null;
      orderData.billingPostcode = null;
      orderData.billingCountry = null;
      _selectedStateCode = null;
    }
    notifyListeners();
  }

  void _initializePaymentMethods() {
    _paymentMethods = [
      PaymentMethod(
        id: 'paymob',
        title: 'Pay Online',
        description: 'Visa • Mastercard • Mada',
        enabled: true,
      ),
      PaymentMethod(
        id: 'cod',
        title: 'Cash/Card on Delivery',
        description: 'Pay with cash or card upon delivery.',
        enabled: true,
      ),
      PaymentMethod(
        id: 'tabby_installments',
        title: 'Tabby',
        description: 'Split in 4. No interest. No fees.',
        enabled: true,
      ),
      PaymentMethod(
        id: 'tamara-gateway',
        title: 'Tamara',
        description: 'Pay in installments with Tamara.',
        enabled: true,
      ),
    ];
    _selectedPaymentMethod = _paymentMethods.first;
    validatePaymentMethods();
    notifyListeners();
  }

  void updateSubtotal(double cartTotal) {
    _subtotal = cartTotal;
    validatePaymentMethods();
    notifyListeners();
  }

  void updateLoyaltyDiscount(double discount) {
    _loyaltyDiscount = discount;
    validatePaymentMethods();
    notifyListeners();
  }

  void validatePaymentMethods() {
    bool tamaraEligible =
        total >= Config.tamaraMinLimit && total <= Config.tamaraMaxLimit;
    bool tabbyEligible =
        total >= Config.tabbyMinLimit && total <= Config.tabbyMaxLimit;

    for (var method in _paymentMethods) {
      if (method.id == 'tamara-gateway') {
        method.enabled = tamaraEligible;
      } else if (method.id == 'tabby_installments') {
        method.enabled = tabbyEligible;
      }
    }

    // If selected method is now disabled, pick another one
    if (_selectedPaymentMethod != null && !_selectedPaymentMethod!.enabled) {
      _selectedPaymentMethod = _paymentMethods.firstWhere((m) => m.enabled);
    }
  }

  Future<void> initializeCheckout(String country, String postcode) async {
    setLoading(true);
    _errorMessage = null;
    developer.log('Initializing checkout...');

    await fetchStates(country);

    if (_errorMessage == null) {
      await Future.wait([
        if (_selectedStateCode != null)
          fetchShippingMethods(
            country,
            _selectedStateCode!,
            postcode,
            cartTotal: _subtotal,
          ),
      ]);
    }

    setLoading(false);
    developer.log('Checkout initialization finished.');
  }

  Future<void> fetchStates(String countryCode) async {
    try {
      final fetchedStates = await _wooCommerceService.getStatesForCountry(
        countryCode,
      );
      _states = fetchedStates;
      _states = fetchedStates;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load regions: ${e.toString()}';
      developer.log(_errorMessage!);
    }
  }

  Future<void> fetchShippingMethods(
    String country,
    String state,
    String postcode, {
    double? cartTotal,
  }) async {
    try {
      final methods = await _wooCommerceService.getShippingMethodsForLocation(
        country,
        state,
        postcode,
        cartTotal: cartTotal,
      );
      _shippingMethods = methods;
      if (_shippingMethods.isNotEmpty) {
        // Prioritize Free Shipping if available
        final freeShipping = _shippingMethods.firstWhere(
          (m) => m.methodId == 'free_shipping',
          orElse: () => _shippingMethods.first,
        );
        _selectedShippingMethod = freeShipping;
        _shippingCost = _selectedShippingMethod!.cost;
        developer.log(
          'Shipping methods fetched. Selected Default: ${_selectedShippingMethod?.title}',
        );
      } else {
        _shippingCost = 0.0;
        developer.log(
          'No shipping methods available for the selected location.',
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to load shipping options: ${e.toString()}';
      developer.log(_errorMessage!);
    } finally {
      notifyListeners();
    }
  }

  void selectState(String stateCode) {
    _selectedStateCode = stateCode;
    orderData.billingState = stateCode;

    // Find the state name to set as city
    final state = _states.firstWhere(
      (s) => s.code == stateCode,
      orElse: () => CountryState(code: stateCode, name: stateCode),
    );
    orderData.billingCity = state.name;

    developer.log('State selection updated: Code=$stateCode, Name=${state.name}');
    fetchShippingMethods('SA', stateCode, '', cartTotal: _subtotal);
    notifyListeners();
  }

  void selectShippingMethod(ShippingMethod method) {
    _selectedShippingMethod = method;
    _shippingCost = method.cost;
    validatePaymentMethods();
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
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
