import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/line_item_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/payment_success_screen.dart';
import 'package:myapp/providers/checkout_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../models/order_payload_model.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/loyalty_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/screens/paymob_payment_screen.dart';
import 'package:myapp/services/paymob_service.dart';
import 'package:myapp/screens/location_picker_screen.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:myapp/screens/tamara_checkout_screen.dart';
import 'package:myapp/services/tamara_service.dart';
import 'package:myapp/screens/tabby_checkout_screen.dart';
import 'package:myapp/services/tabby_service.dart';

class CheckoutScreen extends StatelessWidget {
  final String categoryName;

  const CheckoutScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return _CheckoutScreenView(categoryName: categoryName);
  }
}

class _CheckoutScreenView extends StatefulWidget {
  final String categoryName;

  const _CheckoutScreenView({required this.categoryName});

  @override
  State<_CheckoutScreenView> createState() => _CheckoutScreenViewState();
}

class _CheckoutScreenViewState extends State<_CheckoutScreenView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isPlacingOrder = false;

  final _billingFirstNameController = TextEditingController();
  final _billingLastNameController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _orderNotesController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final checkoutProvider = Provider.of<CheckoutProvider>(
        context,
        listen: false,
      );
      checkoutProvider.reset();

      _initializeCheckoutData(checkoutProvider);

      // Load saved billing details from local storage
      await _loadSavedBillingDetails(checkoutProvider);

      if (!mounted) return;

      final loyalty = Provider.of<LoyaltyProvider>(context, listen: false);
      loyalty.initialize().then((_) {
        if (!mounted) return;
        _updateLoyaltyDiscount(
          checkoutProvider,
          loyalty,
          Provider.of<CartProvider>(context, listen: false),
        );
      });
    });
  }

  @override
  void dispose() {
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingAddress1Controller.dispose();
    _billingPhoneController.dispose();
    _billingEmailController.dispose();
    _orderNotesController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateLoyaltyDiscount(
    CheckoutProvider checkout,
    LoyaltyProvider loyalty,
    CartProvider cart,
  ) {
    if (loyalty.usePoints) {
      final autoPoints = loyalty.getAutomaticDiscount(cart.subtotal);
      checkout.updateLoyaltyDiscount(autoPoints['discount'] as double);
    } else {
      checkout.updateLoyaltyDiscount(0.0);
    }
  }

  void _initializeCheckoutData(CheckoutProvider checkoutProvider) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    checkoutProvider.updateSubtotal(cartProvider.totalAmount);
    checkoutProvider.initializeCheckout('SA', '');
  }

  // Load saved billing details from SharedPreferences
  Future<void> _loadSavedBillingDetails(
    CheckoutProvider checkoutProvider,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _billingFirstNameController.text =
          prefs.getString('billing_first_name') ?? '';
      _billingLastNameController.text =
          prefs.getString('billing_last_name') ?? '';
      _billingPhoneController.text = prefs.getString('billing_phone') ?? '';
      _billingEmailController.text = prefs.getString('billing_email') ?? '';
      _billingAddress1Controller.text =
          prefs.getString('billing_address') ?? '';

      final savedState = prefs.getString('billing_state');
      if (savedState != null && savedState.isNotEmpty) {
        checkoutProvider.selectState(savedState);
      }
    });
  }

  // Save billing details to SharedPreferences
  Future<void> _saveBillingDetails({String? stateCode}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'billing_first_name',
      _billingFirstNameController.text.trim(),
    );
    await prefs.setString(
      'billing_last_name',
      _billingLastNameController.text.trim(),
    );
    await prefs.setString('billing_phone', _billingPhoneController.text.trim());
    await prefs.setString('billing_email', _billingEmailController.text.trim());
    await prefs.setString(
      'billing_address',
      _billingAddress1Controller.text.trim(),
    );
    if (stateCode != null) {
      await prefs.setString('billing_state', stateCode);
    }
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    if (checkoutProvider.selectedPaymentMethod == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.please_select_payment)));
      return;
    }

    if (checkoutProvider.selectedPaymentMethod?.id == 'paymob') {
      _handlePaymobPayment();
      return;
    }

    if (checkoutProvider.selectedPaymentMethod?.id == 'tamara-gateway') {
      _handleTamaraPayment();
      return;
    }

    if (checkoutProvider.selectedPaymentMethod?.id == 'tabby_installments') {
      _handleTabbyPayment();
      return;
    }

    final status = checkoutProvider.selectedPaymentMethod!.id == 'cod'
        ? 'processing'
        : 'pending';
    _createWooCommerceOrder(status: status);
  }

  Future<void> _handlePaymobPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final paymobService = PaymobService();

    setState(() {
      _isPlacingOrder = true;
    });

    // Step 1: Create Initial Order in WooCommerce (Pending)
    final orderResponse = await _createPlaceholderOrder(status: 'pending');
    if (orderResponse == null) {
      setState(() {
        _isPlacingOrder = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.order_failed)));
      return;
    }

    final int wcOrderId = orderResponse['id'];

    final billingData = {
      'firstName': _billingFirstNameController.text.trim(),
      'lastName': _billingLastNameController.text.trim(),
      'email': _billingEmailController.text.trim().isNotEmpty
          ? _billingEmailController.text.trim()
          : 'customer@ucpapp.com',
      'phone': _billingPhoneController.text.trim(),
      'address': _billingAddress1Controller.text.trim(),
      'city': checkoutProvider.selectedStateCode ?? 'Riyadh',
      'state': checkoutProvider.selectedStateCode ?? 'Riyadh',
    };

    final paymentToken = await paymobService.getPaymentToken(
      amount: checkoutProvider.total,
      currency: 'SAR',
      billingData: billingData,
    );

    setState(() {
      _isPlacingOrder = false;
    });

    if (paymentToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_init_failed)));
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymobPaymentScreen(paymentToken: paymentToken),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      // Step 3: Update existing order status to processing
      final wooCommerceService = WooCommerceService();
      await wooCommerceService.updateOrder(wcOrderId, {
        'status': 'processing',
        'set_paid': true,
      });
      _finalizeOrderCompletion(orderResponse);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_failed)));
    }
  }

  Future<void> _handleTabbyPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final tabbyService = TabbyService();

    setState(() {
      _isPlacingOrder = true;
    });

    // Step 1: Create Initial Order in WooCommerce (Pending)
    final orderResponse = await _createPlaceholderOrder(status: 'pending');
    if (orderResponse == null) {
      setState(() {
        _isPlacingOrder = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.order_failed)));
      return;
    }

    final int wcOrderId = orderResponse['id'];

    final billingData = {
      'firstName': _billingFirstNameController.text.trim(),
      'lastName': _billingLastNameController.text.trim(),
      'email': _billingEmailController.text.trim().isNotEmpty
          ? _billingEmailController.text.trim()
          : 'customer@ucpapp.com',
      'phone': _billingPhoneController.text.trim(),
      'address': _billingAddress1Controller.text.trim(),
      'city': checkoutProvider.selectedStateCode ?? 'Riyadh',
    };

    final items = cartProvider.items.values
        .map(
          (item) => {
            'product_id': item.product.id,
            'name': item.product.name,
            'quantity': item.quantity,
            'price': item.product.price,
            'sku': item.product.id.toString(),
          },
        )
        .toList();

    final checkoutResponse = await tabbyService.createCheckout(
      amount: checkoutProvider.total,
      currency: 'SAR',
      billingData: billingData,
      items: items,
      shippingAmount: checkoutProvider.shippingCost,
      taxAmount: checkoutProvider.tax,
      discountAmount:
          checkoutProvider.loyaltyDiscount + cartProvider.discountAmount,
    );

    setState(() {
      _isPlacingOrder = false;
    });

    if (checkoutResponse == null ||
        checkoutResponse['configuration'] == null ||
        checkoutResponse['configuration']['available_products'] == null ||
        (checkoutResponse['configuration']['available_products'] as Map)
            .isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_init_failed)));
      return;
    }

    // Tabby usually provides a web_url inside the response or inside a specific product
    String? checkoutUrl;
    final products =
        checkoutResponse['configuration']['available_products'] as Map;
    if (products.containsKey('installments')) {
      checkoutUrl = products['installments'][0]['web_url'];
    } else {
      // Fallback or handle other types
      checkoutUrl = products.values.first[0]['web_url'];
    }

    if (checkoutUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_init_failed)));
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabbyCheckoutScreen(checkoutUrl: checkoutUrl!),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      // Step 3: Update existing order status to processing
      final wooCommerceService = WooCommerceService();
      await wooCommerceService.updateOrder(wcOrderId, {
        'status': 'processing',
        'set_paid': true,
        'transaction_id': checkoutResponse['id'],
      });
      _finalizeOrderCompletion(orderResponse);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_failed)));
    }
  }

  Future<Map<String, dynamic>?> _createPlaceholderOrder({
    String status = 'pending',
  }) async {
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wooCommerceService = WooCommerceService();

    final orderData = checkoutProvider.orderData;
    orderData.billingFirstName = _billingFirstNameController.text.trim();
    orderData.billingLastName = _billingLastNameController.text.trim();
    orderData.billingAddress1 = _billingAddress1Controller.text.trim();
    orderData.billingCity = checkoutProvider.selectedStateCode ?? '';
    orderData.billingState = checkoutProvider.selectedStateCode ?? '';
    orderData.billingCountry = 'SA';
    orderData.billingEmail = _billingEmailController.text.trim().isNotEmpty
        ? _billingEmailController.text.trim()
        : 'customer@ucpapp.com';
    orderData.billingPhone = _billingPhoneController.text.trim();

    await _saveBillingDetails(stateCode: checkoutProvider.selectedStateCode);

    final billingInfo = BillingInfo(
      firstName: orderData.billingFirstName ?? '',
      lastName: orderData.billingLastName ?? '.',
      address1: orderData.billingAddress1 ?? '',
      city: orderData.billingCity ?? '',
      state: orderData.billingState ?? '',
      postcode: '',
      country: orderData.billingCountry ?? 'SA',
      email: orderData.billingEmail ?? '',
      phone: orderData.billingPhone ?? '',
    );

    final shippingInfo = ShippingInfo.fromBilling(billingInfo);
    final selectedShipping = checkoutProvider.selectedShippingMethod;
    final selectedPayment = checkoutProvider.selectedPaymentMethod!;

    final orderPayload = OrderPayload(
      customerId: orderData.customerId,
      paymentMethod: selectedPayment.id,
      paymentMethodTitle: selectedPayment.title,
      setPaid: false,
      billing: billingInfo,
      shipping: shippingInfo,
      status: status,
      lineItems: cartProvider.items.values
          .map(
            (item) =>
                LineItem(productId: item.product.id, quantity: item.quantity),
          )
          .toList(),
      shippingLines: selectedShipping != null
          ? [
              ShippingLine(
                methodId: selectedShipping.methodId,
                methodTitle: selectedShipping.title,
                total: selectedShipping.cost.toString(),
              ),
            ]
          : [],
      customerNote: _orderNotesController.text,
      couponLines: cartProvider.appliedCoupon != null
          ? [CouponLine(code: cartProvider.appliedCoupon!.code)]
          : [],
      discountAmount:
          cartProvider.discountAmount + checkoutProvider.loyaltyDiscount,
      appliedCouponCode: cartProvider.appliedCoupon?.code,
    );

    final orderResponse = await wooCommerceService.createOrder(orderPayload);

    if (orderResponse != null &&
        orderResponse['id'] != null &&
        orderData.customerId == null) {
      final orderId = orderResponse['id'] as int;
      final box = await Hive.openBox('guest_order_ids');
      final List<int> orderIds = (box.get('ids') as List<dynamic>? ?? [])
          .cast<int>();
      if (!orderIds.contains(orderId)) {
        orderIds.add(orderId);
        await box.put('ids', orderIds);
      }
    }

    return orderResponse;
  }

  Future<void> _finalizeOrderCompletion(
    Map<String, dynamic> orderResponse,
  ) async {
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final loyaltyProvider = Provider.of<LoyaltyProvider>(
      context,
      listen: false,
    );
    final cart = Provider.of<CartProvider>(context, listen: false);

    final earnedPoints = loyaltyProvider.calculateEarnedPoints(cart.subtotal);
    final autoPoints = loyaltyProvider.getAutomaticDiscount(cart.subtotal);
    final pointsUsed = loyaltyProvider.usePoints
        ? (autoPoints['points'] as int)
        : 0;

    if (checkoutProvider.orderData.customerId != null) {
      if (earnedPoints > 0) {
        await loyaltyProvider.commitPointsUpdate(
          userId: checkoutProvider.orderData.customerId!,
          points: earnedPoints,
          operation: 'earn',
          orderId: orderResponse['id'],
        );
      }
      if (pointsUsed > 0) {
        await loyaltyProvider.commitPointsUpdate(
          userId: checkoutProvider.orderData.customerId!,
          points: -pointsUsed,
          operation: 'redeem',
          orderId: orderResponse['id'],
        );
      }
    }

    if (!mounted) return;
    cartProvider.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          orderData: orderResponse,
          categoryName: widget.categoryName,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _handleTamaraPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final tamaraService = TamaraService();

    setState(() {
      _isPlacingOrder = true;
    });

    // Step 1: Create Initial Order in WooCommerce (Pending)
    final orderResponse = await _createPlaceholderOrder(status: 'pending');
    if (orderResponse == null) {
      setState(() {
        _isPlacingOrder = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.order_failed)));
      return;
    }

    final int wcOrderId = orderResponse['id'];

    final billingData = {
      'firstName': _billingFirstNameController.text.trim(),
      'lastName': _billingLastNameController.text.trim(),
      'email': _billingEmailController.text.trim().isNotEmpty
          ? _billingEmailController.text.trim()
          : 'customer@ucpapp.com',
      'phone': _billingPhoneController.text.trim(),
      'address': _billingAddress1Controller.text.trim(),
      'city': checkoutProvider.selectedStateCode ?? 'Riyadh',
      'state': checkoutProvider.selectedStateCode ?? 'Riyadh',
    };

    final items = cartProvider.items.values
        .map(
          (item) => {
            'product_id': item.product.id,
            'name': item.product.name,
            'quantity': item.quantity,
            'price': item.product.price,
            'sku': item.product.id.toString(),
          },
        )
        .toList();

    final checkoutResponse = await tamaraService.createCheckout(
      amount: checkoutProvider.total,
      currency: 'SAR',
      billingData: billingData,
      items: items,
      shippingAmount: checkoutProvider.shippingCost,
      taxAmount: checkoutProvider.tax,
      discountAmount:
          checkoutProvider.loyaltyDiscount + cartProvider.discountAmount,
    );

    setState(() {
      _isPlacingOrder = false;
    });

    if (checkoutResponse == null || checkoutResponse['checkout_url'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_init_failed)));
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TamaraCheckoutScreen(checkoutUrl: checkoutResponse['checkout_url']),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      // Step 3: Update existing order status to processing
      final wooCommerceService = WooCommerceService();
      await wooCommerceService.updateOrder(wcOrderId, {
        'status': 'processing',
        'set_paid': true,
        'transaction_id':
            checkoutResponse['checkout_id'] ?? checkoutResponse['order_id'],
      });
      _finalizeOrderCompletion(orderResponse);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.payment_failed)));
    }
  }

  Future<void> _createWooCommerceOrder({
    bool isPaid = false,
    String? transactionId,
    String? status,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = Provider.of<CheckoutProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wooCommerceService = WooCommerceService();

    setState(() {
      _isPlacingOrder = true;
    });

    final orderData = checkoutProvider.orderData;
    orderData.billingFirstName = _billingFirstNameController.text.trim();
    orderData.billingLastName = _billingLastNameController.text.trim();
    orderData.billingAddress1 = _billingAddress1Controller.text.trim();
    orderData.billingCity = checkoutProvider.selectedStateCode ?? '';
    orderData.billingState = checkoutProvider.selectedStateCode ?? '';
    orderData.billingCountry = 'SA';
    orderData.billingEmail = _billingEmailController.text.trim().isNotEmpty
        ? _billingEmailController.text.trim()
        : 'customer@ucpapp.com';
    orderData.billingPhone = _billingPhoneController.text.trim();

    // Save billing details for future use
    await _saveBillingDetails(stateCode: checkoutProvider.selectedStateCode);

    final billingInfo = BillingInfo(
      firstName: orderData.billingFirstName ?? '',
      lastName: orderData.billingLastName ?? '.',
      address1: orderData.billingAddress1 ?? '',
      city: orderData.billingCity ?? '',
      state: orderData.billingState ?? '',
      postcode: '',
      country: orderData.billingCountry ?? 'SA',
      email: orderData.billingEmail ?? '',
      phone: orderData.billingPhone ?? '',
    );

    final shippingInfo = ShippingInfo.fromBilling(billingInfo);
    final selectedShipping = checkoutProvider.selectedShippingMethod;
    final selectedPayment = checkoutProvider.selectedPaymentMethod!;

    final orderPayload = OrderPayload(
      customerId: orderData.customerId,
      paymentMethod: selectedPayment.id,
      paymentMethodTitle: selectedPayment.title,
      setPaid: isPaid,
      billing: billingInfo,
      shipping: shippingInfo,
      transactionId: transactionId,
      status: status,
      lineItems: cartProvider.items.values
          .map(
            (item) =>
                LineItem(productId: item.product.id, quantity: item.quantity),
          )
          .toList(),
      shippingLines: selectedShipping != null
          ? [
              ShippingLine(
                methodId: selectedShipping.methodId,
                methodTitle: selectedShipping.title,
                total: selectedShipping.cost.toString(),
              ),
            ]
          : [],
      customerNote: _orderNotesController.text,
      couponLines: cartProvider.appliedCoupon != null
          ? [CouponLine(code: cartProvider.appliedCoupon!.code)]
          : [],
      discountAmount:
          cartProvider.discountAmount + checkoutProvider.loyaltyDiscount,
      appliedCouponCode: cartProvider.appliedCoupon?.code,
    );

    final orderResponse = await wooCommerceService.createOrder(orderPayload);

    if (orderResponse != null &&
        orderResponse['id'] != null &&
        orderData.customerId == null) {
      final orderId = orderResponse['id'] as int;
      final box = await Hive.openBox('guest_order_ids');
      final List<int> orderIds = (box.get('ids') as List<dynamic>? ?? [])
          .cast<int>();
      if (!orderIds.contains(orderId)) {
        orderIds.add(orderId);
        await box.put('ids', orderIds);
      }
    }

    if (!mounted) return;

    setState(() {
      _isPlacingOrder = false;
    });

    if (orderResponse != null) {
      final loyaltyProvider = Provider.of<LoyaltyProvider>(
        context,
        listen: false,
      );
      final cart = Provider.of<CartProvider>(context, listen: false);

      final earnedPoints = loyaltyProvider.calculateEarnedPoints(cart.subtotal);
      final autoPoints = loyaltyProvider.getAutomaticDiscount(cart.subtotal);
      final pointsUsed = loyaltyProvider.usePoints
          ? (autoPoints['points'] as int)
          : 0;

      developer.log(
        'LOYALTY: Order Success. ID: ${orderResponse['id']}, CustomerID: ${orderData.customerId}',
      );
      developer.log(
        'LOYALTY: Subtotal: ${cart.subtotal}, Earned: $earnedPoints, Used: $pointsUsed',
      );

      if (orderData.customerId != null) {
        if (earnedPoints > 0) {
          developer.log('LOYALTY: Committing EARN points...');
          await loyaltyProvider.commitPointsUpdate(
            userId: orderData.customerId!,
            points: earnedPoints,
            operation: 'earn',
            orderId: orderResponse['id'],
          );
        }
        if (pointsUsed > 0) {
          developer.log('LOYALTY: Committing REDEEM points...');
          await loyaltyProvider.commitPointsUpdate(
            userId: orderData.customerId!,
            points: -pointsUsed,
            operation: 'redeem',
            orderId: orderResponse['id'],
          );
        }
      } else {
        developer.log(
          'LOYALTY: Skip points update because customerId is null (Guest Order)',
        );
      }

      if (!mounted) return;
      cartProvider.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            orderData: orderResponse,
            categoryName: widget.categoryName,
          ),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.order_failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final checkoutProvider = Provider.of<CheckoutProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: checkoutProvider.currentPage == 0
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => checkoutProvider.previousPage(),
              ),
        title: Text(
          l10n.checkout,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isPlacingOrder
          ? _buildLoadingOverlay()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  _buildModernStepper(checkoutProvider.currentPage),
                  Expanded(
                    child: PageView(
                      controller: checkoutProvider.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildShippingPage(checkoutProvider),
                        _buildPaymentPage(checkoutProvider, currencyProvider),
                        _buildReviewPage(checkoutProvider, currencyProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildModernBottomBar(
        checkoutProvider,
        currencyProvider,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade50, Colors.white, Colors.orange.shade50],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing your order...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStepper(int currentPage) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      {
        'icon': Icons.local_shipping_outlined,
        'label': l10n.shipping,
        'number': '1',
      },
      {'icon': Icons.payment_outlined, 'label': l10n.payment, 'number': '2'},
      {'icon': Icons.check_circle_outline, 'label': l10n.review, 'number': '3'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange.shade50.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          // Determine if this is a step or a connector
          if (index.isEven) {
            // This is a step
            final stepIndex = index ~/ 2;
            bool isActive = stepIndex <= currentPage;
            bool isCurrent = stepIndex == currentPage;
            bool isCompleted = stepIndex < currentPage;

            return Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Step Circle with Number/Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect for current step
                      if (isCurrent)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.orange.withValues(alpha: 0.2),
                                Colors.orange.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      // Main circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width: isCurrent ? 56 : 52,
                        height: isCurrent ? 56 : 52,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF9800),
                                    Color(0xFFFF6F00),
                                  ],
                                )
                              : null,
                          color: isActive ? null : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.5),
                                    blurRadius: isCurrent ? 16 : 12,
                                    spreadRadius: isCurrent ? 3 : 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                          border: Border.all(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : Text(
                                  steps[stepIndex]['number'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Step Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.poppins(
                      fontSize: isCurrent ? 13 : 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? (isCurrent
                                ? Colors.orange.shade700
                                : Colors.orange.shade600)
                          : Colors.grey.shade500,
                      height: 1.2,
                    ),
                    child: Text(
                      steps[stepIndex]['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // This is a connector line
            final stepIndex = index ~/ 2;
            bool isCompleted = stepIndex < currentPage;

            return Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                          )
                        : null,
                    color: isCompleted ? null : Colors.grey.shade200,
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildShippingPage(CheckoutProvider checkout) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernSectionTitle(
              l10n.shipping_details,
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildGlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          _billingFirstNameController,
                          l10n.first_name,
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernTextField(
                          _billingLastNameController,
                          l10n.last_name,
                          Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMapPickerButton(),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _billingAddress1Controller,
                    l10n.address,
                    Icons.home_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildStateDropdown(checkout),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _billingPhoneController,
                    l10n.phone_number,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _billingEmailController,
                    l10n.email,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPickerButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openMapPicker,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.select_location_map,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _billingAddress1Controller.text = result['address'];
      });
    }
  }

  Widget _buildPaymentPage(
    CheckoutProvider checkout,
    CurrencyProvider currencyProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final addressString = [
      '${_billingFirstNameController.text} ${_billingLastNameController.text}',
      _billingAddress1Controller.text,
      checkout.selectedStateCode ?? '',
    ].where((s) => s.trim().isNotEmpty).join('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionTitle(
            '${l10n.review} ${l10n.shipping_details}',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),
          _buildModernReviewCard(
            title: l10n.shipping_to,
            content: addressString,
            icon: Icons.location_on,
          ),
          const SizedBox(height: 24),
          _buildLoyaltyToggleCard(checkout),
          const SizedBox(height: 24),
          _buildModernSectionTitle(l10n.payment_method, Icons.payment_outlined),
          const SizedBox(height: 16),
          _buildModernPaymentMethods(checkout),
          const SizedBox(height: 24),
          _buildModernSectionTitle(l10n.order_notes, Icons.note_outlined),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: _buildModernTextField(
              _orderNotesController,
              l10n.order_notes,
              Icons.edit_note_outlined,
              isOptional: true,
              maxLines: 4,
              hint: l10n.order_notes_hint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage(
    CheckoutProvider checkout,
    CurrencyProvider currencyProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final addressString = [
      '${_billingFirstNameController.text} ${_billingLastNameController.text}',
      _billingAddress1Controller.text,
      checkout.selectedStateCode ?? '',
    ].where((s) => s.trim().isNotEmpty).join('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionTitle(
            l10n.final_review,
            Icons.assignment_turned_in_outlined,
          ),
          const SizedBox(height: 16),
          _buildModernReviewCard(
            title: l10n.shipping_to,
            content: addressString,
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildModernReviewCard(
            title: l10n.payment_method,
            content: _getLocalizedPaymentTitle(
              checkout.selectedPaymentMethod?.id,
              l10n,
            ),
            icon: Icons.payment,
          ),
          const SizedBox(height: 24),
          _buildModernSectionTitle(
            l10n.order_summary,
            Icons.shopping_cart_outlined,
          ),
          const SizedBox(height: 16),
          _buildModernOrderSummaryCard(checkout, currencyProvider),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar(
    CheckoutProvider checkout,
    CurrencyProvider currencyProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    bool isLastPage = checkout.currentPage == 2;
    bool isFirstPage = checkout.currentPage == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLastPage)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.orange.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${currencyProvider.currencySymbol}${checkout.total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isFirstPage) {
                      if (_formKey.currentState!.validate()) {
                        final checkoutProvider = Provider.of<CheckoutProvider>(
                          context,
                          listen: false,
                        );
                        checkoutProvider.orderData.billingFirstName =
                            _billingFirstNameController.text;
                        checkoutProvider.orderData.billingLastName =
                            _billingLastNameController.text;
                        checkoutProvider.orderData.billingAddress1 =
                            _billingAddress1Controller.text;
                        checkoutProvider.orderData.billingPhone =
                            _billingPhoneController.text;
                        checkoutProvider.orderData.billingEmail =
                            _billingEmailController.text;

                        // Save details automatically when moving to next step
                        _saveBillingDetails(
                          stateCode: checkoutProvider.selectedStateCode,
                        );

                        checkoutProvider.nextPage();
                      }
                    } else if (isLastPage) {
                      _placeOrder();
                    } else {
                      checkout.nextPage();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? l10n.place_order : l10n.continue_step,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool isOptional = false,
    int maxLines = 1,
    String? hint,
    bool enabled = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.orange.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return l10n.err_please_enter(label);
        }
        // If not empty, and it's an email field, validate format
        if (value != null && value.isNotEmpty && label == l10n.email) {
          if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(value)) {
            return l10n.err_invalid_email;
          }
        }
        return null;
      },
    );
  }

  Widget _buildLoyaltyToggleCard(CheckoutProvider checkout) {
    return Consumer<LoyaltyProvider>(
      builder: (context, loyalty, child) {
        if (loyalty.loyaltyData == null ||
            loyalty.loyaltyData!.pointsBalance <= 0) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final cart = Provider.of<CartProvider>(context, listen: false);
        final currency = Provider.of<CurrencyProvider>(context, listen: false);
        final autoDiscount = loyalty.getAutomaticDiscount(cart.subtotal);
        final discountValue = autoDiscount['discount'] as double;
        final pointsToUse = autoDiscount['points'] as int;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: loyalty.usePoints
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: loyalty.usePoints
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: loyalty.usePoints ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: loyalty.usePoints
                            ? Colors.orange.shade100
                            : Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        loyalty.usePoints ? Icons.stars : Icons.stars_outlined,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.use_points_for_discount,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n.points_balance_summary(
                              loyalty.loyaltyData!.pointsBalance,
                              l10n.pts_suffix,
                            ),
                            style: GoogleFonts.notoSansArabic(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: loyalty.usePoints,
                      activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                      activeThumbColor: Colors.orange,
                      onChanged: (value) {
                        loyalty.toggleUsePoints(value);
                        _updateLoyaltyDiscount(checkout, loyalty, cart);
                      },
                    ),
                  ],
                ),
              ),
              if (loyalty.usePoints && discountValue > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.points_redeem_summary(
                            pointsToUse,
                            l10n.pts_suffix,
                            currency.currencySymbol,
                            discountValue.toStringAsFixed(2),
                          ),
                          style: GoogleFonts.notoSansArabic(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateDropdown(CheckoutProvider checkout) {
    final l10n = AppLocalizations.of(context)!;
    if (checkout.isLoading && checkout.states.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (checkout.errorMessage != null) {
      return Text(
        '${l10n.unknown_error}: ${checkout.errorMessage}',
        style: const TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<String>(
      value: checkout.selectedStateCode,
      hint: Text(l10n.select_region),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_city, color: Colors.orange.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      items: checkout.states.map((CountryState state) {
        return DropdownMenuItem<String>(
          value: state.code,
          child: Text(state.name, style: GoogleFonts.poppins(fontSize: 15)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          checkout.selectState(newValue);
        }
      },
      validator: (value) => value == null ? l10n.select_region : null,
    );
  }

  String _getLocalizedPaymentTitle(String? id, AppLocalizations l10n) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    switch (id) {
      case 'cod':
        return isArabic ? 'الدفع عند الاستلام' : 'Cash on Delivery';
      case 'paymob':
        return isArabic ? 'الدفع أونلاين' : 'Pay Online';
      case 'tamara-gateway':
        return isArabic ? 'تمارا' : 'Tamara';
      case 'tabby_installments':
        return isArabic ? 'تابي' : 'Tabby';
      default:
        return id ?? '';
    }
  }

  String _getLocalizedPaymentDescription(String? id, AppLocalizations l10n) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    switch (id) {
      case 'cod':
        return isArabic
            ? 'الدفع نقداً أو بالبطاقة عند الاستلام.'
            : 'Pay with cash or card upon delivery.';
      case 'paymob':
        return isArabic
            ? 'مدى • ماستركارد • فيزا'
            : 'Visa • Mastercard • Mada';
      case 'tamara-gateway':
        return isArabic
            ? 'قسّم دفعاتك مع تمارا بدون فوائد.'
            : 'Pay in installments with Tamara.';
      case 'tabby_installments':
        return isArabic
            ? 'قسّمها على 4 دفعات بدون فوائد أو رسوم.'
            : 'Split in 4. No interest. No fees.';
      default:
        return '';
    }
  }

  Widget _buildModernPaymentMethods(CheckoutProvider checkout) {
    if (checkout.paymentMethods.isEmpty) {
      return const Text('No payment methods available.');
    }
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: checkout.paymentMethods.map((method) {
        final isSelected = checkout.selectedPaymentMethod?.id == method.id;
        final isEnabled = method.enabled;

        return Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: GestureDetector(
            onTap: isEnabled
                ? () => checkout.selectPaymentMethod(method)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (method.id.contains('tamara'))
                            ? Image.asset(
                                'assets/images/tamara-logo.png',
                                width: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.payment,
                                        color: isSelected
                                            ? Colors.orange
                                            : Colors.orange.shade700),
                              )
                            : (method.id.contains('tabby'))
                                ? Image.asset(
                                    'assets/images/tabby-logo.png',
                                    width: 40,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.payment,
                                            color: isSelected
                                                ? Colors.orange
                                                : Colors.orange.shade700),
                                  )
                                : Icon(
                                    method.id == 'paymob'
                                        ? Icons.credit_card_outlined
                                        : (method.id == 'cod'
                                            ? Icons.payments_outlined
                                            : Icons.credit_card_outlined),
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.orange.shade700,
                                    size: 24,
                                  ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getLocalizedPaymentTitle(method.id, l10n),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (method.id == 'paymob')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildSmallLogo('assets/images/Apple_Pay_logo.png', isAsset: true),
                                        _buildSmallLogo('assets/images/Mada.png', isAsset: true),
                                        _buildSmallLogo('assets/images/visa.png', isAsset: true),
                                        _buildSmallLogo('assets/images/mastercard.png', isAsset: true),
                                      ],
                                    ),
                                  ),
                                if (method.id != 'paymob' && method.description.isNotEmpty)
                                  Text(
                                    _getLocalizedPaymentDescription(method.id, l10n),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                    ],
                  ),
                ),
                if (!isEnabled &&
                    (method.id.contains('tamara') ||
                        method.id.contains('tabby')))
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      method.id.contains('tamara')
                          ? 'متاح للطلبات بين 99 و 3000 ريال'
                          : 'متاح للطلبات بين 10 و 5000 ريال',
                      style: GoogleFonts.notoSansArabic(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallLogo(String path, {bool isAsset = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
          ),
        ],
      ),
      child: isAsset
          ? Image.asset(path, width: 22, height: 14, fit: BoxFit.contain)
          : Image.network(path, width: 22, height: 14, fit: BoxFit.contain),
    );
  }

  Widget _buildModernReviewCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrderSummaryCard(
    CheckoutProvider checkout,
    CurrencyProvider currencyProvider,
  ) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ...cart.items.values.map((item) {
            final price = item.product.price ?? 0.0;
            final lineTotal = price * item.quantity;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.product.name} (x${item.quantity})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${currencyProvider.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 30, thickness: 1.5),
          _buildModernSummaryRow(
            l10n.subtotal,
            cart.subtotal,
            currencyProvider,
          ),
          if (cart.discountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: _buildModernSummaryRow(
                l10n.discount,
                cart.discountAmount,
                currencyProvider,
                isDiscount: true,
              ),
            ),
          const SizedBox(height: 10),
          _buildModernSummaryRow(
            l10n.shipping,
            checkout.shippingCost,
            currencyProvider,
          ),
          const SizedBox(height: 10),
          _buildModernSummaryRow(l10n.tax, checkout.tax, currencyProvider),
          if (checkout.loyaltyDiscount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: _buildModernSummaryRow(
                l10n.points_discount,
                checkout.loyaltyDiscount,
                currencyProvider,
                isDiscount: true,
              ),
            ),
          const Divider(height: 30, thickness: 1.5),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${currencyProvider.currencySymbol}${checkout.total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPointsInfo(context),
        ],
      ),
    );
  }

  Widget _buildPointsInfo(BuildContext context) {
    final loyalty = Provider.of<LoyaltyProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    if (loyalty.loyaltyData == null) return const SizedBox.shrink();

    // Hide the box entirely if using points as per user request for review page
    if (loyalty.usePoints) return const SizedBox.shrink();

    final earned = loyalty.calculateEarnedPoints(cart.subtotal);
    if (earned <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.earn_points_banner_title,
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    l10n.earn_points_banner_subtitle,
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+$earned ${l10n.pts_suffix}',
              style: GoogleFonts.poppins(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryRow(
    String label,
    double amount,
    CurrencyProvider currencyProvider, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
      color: isDiscount ? Colors.green.shade700 : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${isDiscount ? '- ' : ''}${currencyProvider.currencySymbol}${amount.toStringAsFixed(2)}',
          style: style,
        ),
      ],
    );
  }
}
