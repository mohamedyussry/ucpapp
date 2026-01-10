
import 'package:flutter/material.dart';
import 'package:myapp/models/payment_method_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart'; // Import Dio
import 'package:myapp/config.dart'; // Import Config

class ShippingMethod {
  final int instanceId;
  final String title;
  final String methodId;
  final double cost;
  final String zoneName;

  ShippingMethod({
    required this.instanceId,
    required this.title,
    required this.methodId,
    required this.cost,
    required this.zoneName,
  });
}

class CheckoutProvider with ChangeNotifier {
  final WooCommerceService _wooCommerceService = WooCommerceService();

  int _currentPage = 0;
  final PageController pageController = PageController();

  List<ShippingMethod> _shippingMethods = [];
  ShippingMethod? _selectedShippingMethod;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  List<CountryState> _states = [];
  String? _selectedStateCode;

  double _subtotal = 0;
  final double _tax = 0;
  bool _isLoading = false;
  String? _errorMessage;

  int get currentPage => _currentPage;
  List<ShippingMethod> get shippingMethods => _shippingMethods;
  ShippingMethod? get selectedShippingMethod => _selectedShippingMethod;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  List<CountryState> get states => _states;
  String? get selectedStateCode => _selectedStateCode;
  double get shippingCost => _selectedShippingMethod?.cost ?? 0;
  double get tax => _tax;
  double get subtotal => _subtotal;
  double get total => _subtotal + shippingCost + tax;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateSubtotal(double cartTotal) {
    _subtotal = cartTotal;
    notifyListeners();
  }

  Future<void> initializeCheckout(String country, String postcode) async {
    setLoading(true);
    _errorMessage = null; // Clear previous errors
    developer.log('Initializing checkout...');

    await fetchStates(country);

    // Only fetch shipping/payment if states were fetched successfully
    if (_errorMessage == null) {
      await Future.wait([
        if (_selectedStateCode != null)
          fetchShippingMethods(country, _selectedStateCode!, postcode),
        fetchPaymentMethods(),
      ]);
    }

    developer.log('Checkout initialization complete.');
    setLoading(false);
  }

  Future<void> fetchShippingMethods(String country, String state, String postcode) async {
    _shippingMethods = [];
    _selectedShippingMethod = null;
    
    try {
      _shippingMethods = await _wooCommerceService.getShippingMethodsForLocation(country, state, postcode);
      if (_shippingMethods.isNotEmpty) {
        _selectedShippingMethod = _shippingMethods.first;
      }
      developer.log('Fetched ${_shippingMethods.length} shipping methods for state $state.');
    } catch (e) {
      developer.log("Error fetching shipping methods: $e");
      _errorMessage = 'Error fetching shipping methods: $e';
      _shippingMethods = [];
      _selectedShippingMethod = null;
    }
  }

  Future<void> fetchPaymentMethods() async {
    try {
      _paymentMethods = await _wooCommerceService.getPaymentMethods();
      if (_paymentMethods.isNotEmpty) {
        _selectedPaymentMethod = _paymentMethods.first;
      } else {
        _selectedPaymentMethod = null;
      }
      developer.log('Fetched ${_paymentMethods.length} payment methods.');
    } catch (e) {
      developer.log("Error fetching payment methods: $e");
      _errorMessage = 'Error fetching payment methods: $e';
      _paymentMethods = [];
      _selectedPaymentMethod = null;
    }
  }

  // RADICAL CHANGE: Directly fetch states within the provider to bypass service interaction issues.
  Future<void> fetchStates(String countryCode) async {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: '${Config.wooCommerceUrl}/wp-json/wc/v3',
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ),
    );

    try {
      final response = await dio.get(
        '/data/countries/$countryCode',
        queryParameters: {
          'consumer_key': Config.consumerKey,
          'consumer_secret': Config.consumerSecret,
        },
      );

      if (response.statusCode == 200 && response.data['states'] is List) {
        _states = (response.data['states'] as List)
            .map((s) => CountryState.fromJson(s))
            .toList();
         if (_states.isNotEmpty) {
            _selectedStateCode = _states.first.code;
         } else {
            _selectedStateCode = null;
         }
        _errorMessage = null;
        developer.log('Fetched ${_states.length} states directly. Default selected: $_selectedStateCode');
      } else {
        throw 'Failed to fetch states for $countryCode. Status: ${response.statusCode}, Body: ${response.data}';
      }

    } catch (e) {
      developer.log("Error fetching states directly: $e");
      _errorMessage = e.toString(); // Capture the specific error message
      _states = [];
      _selectedStateCode = null;
    }
  }

  void selectShippingMethod(ShippingMethod method) {
    if (_selectedShippingMethod?.instanceId != method.instanceId) {
      _selectedShippingMethod = method;
      notifyListeners();
    }
  }

  void selectPaymentMethod(PaymentMethod method) {
    if (_selectedPaymentMethod?.id != method.id) {
      _selectedPaymentMethod = method;
      notifyListeners();
    }
  }

  Future<void> selectState(String stateCode) async {
    if (_selectedStateCode != stateCode) {
      setLoading(true);
      _selectedStateCode = stateCode;
      _errorMessage = null; // Clear error on new selection
      developer.log('State selected: $stateCode. Refetching shipping methods.');
      await fetchShippingMethods('SA', stateCode, '');
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.ease);
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.ease);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
