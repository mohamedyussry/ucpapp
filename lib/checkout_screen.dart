
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

// Wrapper widget to provide the CheckoutProvider
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider(),
      child: const _CheckoutScreenView(),
    );
  }
}

class _CheckoutScreenView extends StatefulWidget {
  const _CheckoutScreenView();

  @override
  State<_CheckoutScreenView> createState() => _CheckoutScreenViewState();
}

class _CheckoutScreenViewState extends State<_CheckoutScreenView> {
  final _formKey = GlobalKey<FormState>();
  bool _isPlacingOrder = false;

  // Simplified Controllers
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
    // Dispose simplified controllers
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
    
    // We still initialize with country code 'SA' in the background
    checkoutProvider.initializeCheckout('SA', '');
  }

  Future<void> _placeOrder() async {
     if (!_formKey.currentState!.validate()) return;

    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final selectedState = checkoutProvider.selectedStateCode;

    if (checkoutProvider.states.isNotEmpty && selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a region.')),
      );
      return;
    }

    // Check for shipping method is still valid, as it's selected in the background
    if (checkoutProvider.shippingMethods.isNotEmpty && checkoutProvider.selectedShippingMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No shipping method available for your region.')),
        );
        return;
    }

    // User must now select a payment method
    if (checkoutProvider.paymentMethods.isNotEmpty && checkoutProvider.selectedPaymentMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a payment method.')),
        );
        return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wooCommerceService = WooCommerceService();

    // --- Logic to split full name ---
    final fullName = _billingFullNameController.text.trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '.'; // Use a dot if last name is empty
    // --- End of name logic ---

    final billingInfo = BillingInfo(
        firstName: firstName,
        lastName: lastName,
        address1: _billingAddress1Controller.text,
        city: selectedState ?? '', // Use state as city
        state: selectedState ?? '',
        postcode: '', // Optional
        country: 'SA', // Hardcoded country
        email: _billingEmailController.text, // Optional
        phone: _billingPhoneController.text); // Required

    // For simplicity, shipping is always the same as billing
    final shippingInfo = ShippingInfo.fromBilling(billingInfo);
    
    final selectedShipping = checkoutProvider.selectedShippingMethod;
    final selectedPayment = checkoutProvider.selectedPaymentMethod!;

    final orderPayload = OrderPayload(
      paymentMethod: selectedPayment.id,
      paymentMethodTitle: selectedPayment.title,
      setPaid: false,
      billing: billingInfo,
      shipping: shippingInfo,
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

    if (!mounted) return;

    setState(() {
      _isPlacingOrder = false;
    });

    if (orderResponse != null) {
      cartProvider.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Checkout', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkout, child) {
          if (checkout.isLoading && checkout.states.isEmpty && checkout.paymentMethods.isEmpty) {
             return const Center(child: CircularProgressIndicator());
          }
          return _isPlacingOrder
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Billing Details'),
                        _buildBillingForm(checkout),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Your Order'),
                        _buildOrderCard(checkout, currencyProvider),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Order Notes'),
                        _buildOrderNotesField(),
                        const SizedBox(height: 100), // padding for bottom bar
                      ],
                    ),
                  ),
                );
        },
      ),
      bottomNavigationBar: Consumer<CheckoutProvider>(
        builder: (context, checkout, child) => _buildBottomBar(checkout, currencyProvider),
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildOrderCard(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(checkout, currencyProvider),
            // --- Shipping Methods Section Removed ---
            const Divider(height: 24),
            Text('Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPaymentMethods(checkout),
          ],
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

  Widget _buildBillingForm(CheckoutProvider checkout) {
    return Column(
      children: [
        _buildTextField(_billingFullNameController, 'Full Name'), // Changed label
        _buildTextField(_billingAddress1Controller, 'Address'),
        _buildStateDropdown(checkout),
        _buildTextField(_billingPhoneController, 'Phone', keyboardType: TextInputType.phone), // Made mandatory by default validator
        _buildTextField(_billingEmailController, 'Email', keyboardType: TextInputType.emailAddress, isOptional: true), // Made optional
      ].map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList(),
    );
  }

  Widget _buildStateDropdown(CheckoutProvider checkout) {
    if (checkout.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error: Could not load regions.\nDetails: ${checkout.errorMessage}',
          style: GoogleFonts.poppins(color: Colors.red[700], fontWeight: FontWeight.w500),
        ),
      );
    }

    if (checkout.isLoading && checkout.states.isEmpty) {
      return _buildTextField(
        TextEditingController(text: 'Loading regions...'),
        'Region',
        enabled: false,
      );
    }
    
    if (!checkout.isLoading && checkout.states.isEmpty) {
      return _buildTextField(
        TextEditingController(text: 'No regions available'),
        'Region',
        enabled: false,
      );
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
      onChanged: checkout.isLoading ? null : (String? newValue) {
        if (newValue != null) {
          checkout.selectState(newValue);
        }
      },
      validator: (value) => value == null ? 'Please select a region' : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: checkout.isLoading, 
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildOrderNotesField() {
    return _buildTextField(_orderNotesController, 'Order Notes', isOptional: true, maxLines: 3, hint: 'Notes about your order, e.g. special notes for delivery.');
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, bool isOptional = false, int maxLines = 1, String? hint, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: !enabled,
        fillColor: Colors.grey[100],
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        if (label == 'Phone' && (value == null || value.length < 9)) { // Example validation for phone
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethods(CheckoutProvider checkout) {
    if (checkout.isLoading && checkout.paymentMethods.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }

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
          labelStyle: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              checkout.selectPaymentMethod(method);
            }
          },
          selectedColor: Colors.orange,
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade300)
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    return Column(
      children: [
        _buildSummaryRow('Subtotal', checkout.subtotal, currencyProvider),
        const SizedBox(height: 8),
        _buildSummaryRow('Shipping', checkout.shippingCost, currencyProvider),
        const SizedBox(height: 8),
        _buildSummaryRow('Tax', checkout.tax, currencyProvider),
        const Divider(height: 20, thickness: 1),
        _buildSummaryRow('Total', checkout.total, currencyProvider, isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, CurrencyProvider currencyProvider, {bool isTotal = false}) {
    final style = GoogleFonts.poppins(
        fontSize: isTotal ? 16 : 14,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Row(
          children: [
            Text('${amount.toStringAsFixed(2)} ', style: style),
            _buildCurrencyDisplay(currencyProvider, isTotal ? 16 : 14, color: Colors.black)
          ],
        )
      ],
    );
  }

  Widget _buildBottomBar(CheckoutProvider checkout, CurrencyProvider currencyProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(51), spreadRadius: 2, blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Place Order', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 10),
            Text('${checkout.total.toStringAsFixed(2)} ', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            _buildCurrencyDisplay(currencyProvider, 16, color: Colors.white)
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay(CurrencyProvider currencyProvider, double size, {Color? color}) {
    final currencyImageUrl = currencyProvider.currencyImageUrl;
    final currencySymbol = currencyProvider.currencySymbol;

    final style = GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.bold, color: color);

    if (currencyImageUrl != null && currencyImageUrl.isNotEmpty) {
      return Image.network(
        currencyImageUrl,
        height: size,
        color: color,
        errorBuilder: (context, error, stackTrace) => Text(currencySymbol, style: style),
      );
    } else {
      return Text(currencySymbol, style: style);
    }
  }
}
