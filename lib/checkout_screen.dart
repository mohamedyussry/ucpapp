
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/line_item_model.dart';
import 'package:myapp/models/state_model.dart';
import 'package:myapp/payment_success_screen.dart';
import 'package:myapp/providers/checkout_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../models/order_payload_model.dart';
import '../providers/cart_provider.dart';
import '../services/woocommerce_service.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:hive/hive.dart';

class CheckoutScreen extends StatelessWidget {
  final String categoryName;

  const CheckoutScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider(),
      child: _CheckoutScreenView(categoryName: categoryName),
    );
  }
}

class _CheckoutScreenView extends StatefulWidget {
  final String categoryName;

  const _CheckoutScreenView({required this.categoryName});

  @override
  State<_CheckoutScreenView> createState() => _CheckoutScreenViewState();
}

class _CheckoutScreenViewState extends State<_CheckoutScreenView> {
  final _formKey = GlobalKey<FormState>();
  bool _isPlacingOrder = false;

  final _billingFullNameController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _orderNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckoutData();
    });
  }

  @override
  void dispose() {
    _billingFullNameController.dispose();
    _billingAddress1Controller.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  void _initializeCheckoutData() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    checkoutProvider.updateSubtotal(cartProvider.totalAmount);
    checkoutProvider.initializeCheckout('SA', '');
  }

  Future<void> _placeOrder() async {
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);

    if (checkoutProvider.paymentMethods.isNotEmpty && checkoutProvider.selectedPaymentMethod == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    if (checkoutProvider.selectedPaymentMethod!.id == 'paymob') {
      _handlePaymobPayment();
    } else {
      _createWooCommerceOrder();
    }
  }

  Future<void> _handlePaymobPayment() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
      if (!mounted) return;

      final isSuccess = await FlutterPaymob.instance.payWithCard(
        context: context,
        currency: 'EGP',
        amount: checkoutProvider.total,
      );

      if (isSuccess) {
        final tempTransactionId = 'paymob_success_${DateTime.now().millisecondsSinceEpoch}';
        _createWooCommerceOrder(isPaid: true, transactionId: tempTransactionId);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed or was cancelled. Please try again.')),
        );
         if (mounted) {
          setState(() {
            _isPlacingOrder = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }


  Future<void> _createWooCommerceOrder({bool isPaid = false, String? transactionId}) async {
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wooCommerceService = WooCommerceService();

    if (!_isPlacingOrder) {
      setState(() {
        _isPlacingOrder = true;
      });
    }

    final fullName = _billingFullNameController.text.trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '.';

    final billingInfo = BillingInfo(
      firstName: firstName,
      lastName: lastName,
      address1: _billingAddress1Controller.text,
      city: checkoutProvider.selectedStateCode ?? '',
      state: checkoutProvider.selectedStateCode ?? '',
      postcode: '',
      country: 'SA',
      email: _billingEmailController.text,
      phone: _billingPhoneController.text,
    );

    final shippingInfo = ShippingInfo.fromBilling(billingInfo);
    final selectedShipping = checkoutProvider.selectedShippingMethod;
    final selectedPayment = checkoutProvider.selectedPaymentMethod!;

    final orderPayload = OrderPayload(
      paymentMethod: selectedPayment.id,
      paymentMethodTitle: selectedPayment.title,
      setPaid: isPaid,
      billing: billingInfo,
      shipping: shippingInfo,
      transactionId: transactionId,
      lineItems: cartProvider.items.values
          .map((item) => LineItem(productId: item.product.id, quantity: item.quantity))
          .toList(),
      shippingLines: selectedShipping != null
          ? [
              ShippingLine(
                methodId: selectedShipping.methodId,
                methodTitle: selectedShipping.title,
                total: selectedShipping.cost.toString(),
              )
            ]
          : [],
      customerNote: _orderNotesController.text,
    );

    final orderResponse = await wooCommerceService.createOrder(orderPayload);

    if (orderResponse != null && orderResponse['id'] != null) {
      final orderId = orderResponse['id'] as int;
      final box = await Hive.openBox('guest_order_ids');
      final List<int> orderIds = (box.get('ids') as List<dynamic>? ?? []).cast<int>();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final checkoutProvider = Provider.of<CheckoutProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: checkoutProvider.currentPage == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => checkoutProvider.previousPage(),
              ),
        title: Text('Checkout', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isPlacingOrder
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStepper(checkoutProvider.currentPage),
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
      bottomNavigationBar: _buildBottomBar(checkoutProvider, currencyProvider),
    );
  }

  Widget _buildStepper(int currentPage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isActive = index <= currentPage;
          return Expanded(
            child: Column(
              children: [
                Text(
                  ['Shipping', 'Payment', 'Review'][index],
                  style: GoogleFonts.poppins(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.orange : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }).expand((widget) => [widget, const SizedBox(width: 10)]).toList(),
      ),
    );
  }

  Widget _buildShippingPage(CheckoutProvider checkout) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Shipping Details'),
            _buildTextField(_billingFullNameController, 'Full Name'),
            const SizedBox(height: 10),
            _buildTextField(_billingAddress1Controller, 'Address'),
            const SizedBox(height: 10),
            _buildStateDropdown(checkout),
             const SizedBox(height: 10),
            _buildTextField(_billingPhoneController, 'Phone', keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _buildTextField(_billingEmailController, 'Email', keyboardType: TextInputType.emailAddress, isOptional: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPage(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionTitle('Review Shipping Details'),
          _buildReviewCard(
            title: 'Shipping To',
            content: 
                '${_billingFullNameController.text}\n${_billingAddress1Controller.text}\n${checkout.selectedStateCode ?? ''}',
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Payment Method'),
          _buildPaymentMethods(checkout),
          const SizedBox(height: 20),
          _buildSectionTitle('Order Notes'),
          _buildTextField(_orderNotesController, 'Order Notes', isOptional: true, maxLines: 3, hint: 'Notes about your order...'),
        ],
      ),
    );
  }

  Widget _buildReviewPage(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Final Review'),
          _buildReviewCard(
            title: 'Shipping To',
            content:
                '${_billingFullNameController.text}\n${_billingAddress1Controller.text}\n${checkout.selectedStateCode ?? ''}',
          ),
          const SizedBox(height: 10),
          _buildReviewCard(
            title: 'Payment Method',
            content: checkout.selectedPaymentMethod?.title ?? 'Not Selected',
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Order Summary'),
          _buildOrderSummaryCard(checkout, currencyProvider),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    bool isLastPage = checkout.currentPage == 2;
    bool isFirstPage = checkout.currentPage == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(51), spreadRadius: 2, blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isFirstPage) {
            if (_formKey.currentState!.validate()) {
              checkout.nextPage();
            }
          } else if (isLastPage) {
            _placeOrder();
          } else {
            checkout.nextPage();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          isLastPage ? 'Place Order' : 'Continue',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, bool isOptional = false, int maxLines = 1, String? hint, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildStateDropdown(CheckoutProvider checkout) {
    if (checkout.isLoading && checkout.states.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (checkout.errorMessage != null) {
      return Text('Error: ${checkout.errorMessage}', style: const TextStyle(color: Colors.red));
    }

    return DropdownButtonFormField<String>(
      initialValue: checkout.selectedStateCode,
      hint: const Text('Select Region'),
      isExpanded: true,
      items: checkout.states.map((CountryState state) {
        return DropdownMenuItem<String>(
          value: state.code,
          child: Text(state.name),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          checkout.selectState(newValue);
        }
      },
      validator: (value) => value == null ? 'Please select a region' : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPaymentMethods(CheckoutProvider checkout) {
    if (checkout.paymentMethods.isEmpty) {
      return const Text('No payment methods available.');
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: checkout.paymentMethods.map((method) {
        final isSelected = checkout.selectedPaymentMethod?.id == method.id;
        return ChoiceChip(
          label: Text(method.title),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              checkout.selectPaymentMethod(method);
            }
          },
          selectedColor: Colors.orange,
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

   Widget _buildReviewCard({required String title, required String content}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content, style: GoogleFonts.poppins(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...cart.items.values.map((item) {
              final price = item.product.price ?? 0.0;
              final lineTotal = price * item.quantity;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.product.name} (x${item.quantity})'),
                    Text('${currencyProvider.currencySymbol}${lineTotal.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
            const Divider(height: 20, thickness: 1),
            _buildSummaryRow('Subtotal', checkout.subtotal, currencyProvider),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping', checkout.shippingCost, currencyProvider),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax', checkout.tax, currencyProvider),
            const Divider(height: 20, thickness: 1),
            _buildSummaryRow('Total', checkout.total, currencyProvider, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, CurrencyProvider currencyProvider, {bool isTotal = false}) {
    final style = GoogleFonts.poppins(
        fontSize: isTotal ? 16 : 14,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('${currencyProvider.currencySymbol}${amount.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
