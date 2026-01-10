import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/home_screen.dart'; // Import the home screen

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String categoryName;

  const PaymentSuccessScreen({
    super.key,
    required this.orderData,
    required this.categoryName,
  });

  String? _extractImageUrl(String? htmlString) {
    if (htmlString == null) return null;
    final RegExp regExp = RegExp(r'src="(.*?)"');
    final Match? match = regExp.firstMatch(htmlString);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = orderData['id']?.toString() ?? 'N/A';
    final double totalAmount = double.tryParse(orderData['total']?.toString() ?? '0.0') ?? 0.0;
    final String dateCreated = orderData['date_created'] != null
        ? DateFormat('MMMM dd, yyyy').format(DateTime.parse(orderData['date_created']))
        : 'N/A';
    final String paymentMethod = orderData['payment_method_title'] ?? 'N/A';
    final String status = orderData['status']?.toString() ?? 'N/A';
    final String? currencyImageUrl = _extractImageUrl(orderData['currency_symbol']);

    final Map<String, dynamic> billingInfo = orderData['billing'] ?? {};
    final String billingAddress = '''
${billingInfo['first_name'] ?? ''} ${billingInfo['last_name'] ?? ''}
${billingInfo['address_1'] ?? ''}, ${billingInfo['city'] ?? ''}
${billingInfo['state'] ?? ''}, ${billingInfo['country'] ?? ''}
''';

    final List<dynamic> lineItems = orderData['line_items'] ?? [];

    void navigateToHome() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false, 
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: navigateToHome, 
        ),
        title: Text('Order Confirmed', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('Order Details'),
            _buildCombinedDetailsCard(
              orderId: orderId,
              dateCreated: dateCreated,
              paymentMethod: paymentMethod,
              status: status,
              billingAddress: billingAddress,
              lineItems: lineItems,
              totalAmount: totalAmount,
              currencyImageUrl: currencyImageUrl,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContinueShoppingButton(context, navigateToHome), 
        ),
      ),
    );
  }

  Widget _buildConfirmationHeader() {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange,
            child: Icon(Icons.check, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text('Thank You For Your Order!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            'Your order has been placed successfully.',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.black54)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: valueColor ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildCombinedDetailsCard({
    required String orderId,
    required String dateCreated,
    required String paymentMethod,
    required String status,
    required String billingAddress,
    required List<dynamic> lineItems,
    required double totalAmount,
    required String? currencyImageUrl,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Order ID:', '#$orderId'),
            _buildDetailRow('Date:', dateCreated),
            _buildDetailRow('Payment Method:', paymentMethod),
            _buildDetailRow('Status:', status.toUpperCase(), valueColor: Colors.orange),
            const Divider(height: 24, thickness: 1),
            Text('Shipping Address', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(billingAddress, style: GoogleFonts.poppins(height: 1.5)),
            const Divider(height: 24, thickness: 1),
            Text('Order Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...lineItems.map((item) {
              final String name = item['name'] ?? 'N/A';
              final int quantity = item['quantity'] ?? 0;
              final String itemTotal = item['total'] ?? '0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('$name (x$quantity)', style: GoogleFonts.poppins())),
                    Row(
                      children: [
                        if (currencyImageUrl != null)
                          Image.network(currencyImageUrl, height: 16, errorBuilder: (c, o, s) => const SizedBox()),
                        const SizedBox(width: 4),
                        Text(double.tryParse(itemTotal)?.toStringAsFixed(2) ?? '0.00', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                Row(
                  children: [
                    if (currencyImageUrl != null)
                      Image.network(currencyImageUrl, height: 20, errorBuilder: (c, o, s) => const SizedBox()),
                    const SizedBox(width: 4),
                    Text(totalAmount.toStringAsFixed(2), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rewritten button for robust layout
  Widget _buildContinueShoppingButton(BuildContext context, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity, // Ensures the button takes the full width
        height: 56, // Provides a consistent and modern height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center( // Centers the text perfectly
          child: Text(
            'Continue Shopping',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
