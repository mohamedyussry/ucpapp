import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/models/order_model.dart';
import 'package:myapp/order_tracking_screen.dart';
import 'l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final int orderId = orderData['id'] as int? ?? 0;
    final double totalAmount =
        double.tryParse(orderData['total']?.toString() ?? '0.0') ?? 0.0;
    final String dateCreated = orderData['date_created'] != null
        ? DateFormat(
            'MMMM dd, yyyy',
          ).format(DateTime.parse(orderData['date_created']))
        : 'N/A';
    final String paymentMethod = orderData['payment_method_title'] ?? 'N/A';
    final String status = orderData['status']?.toString() ?? 'N/A';
    final String? currencyImageUrl = _extractImageUrl(
      orderData['currency_symbol'],
    );

    final Map<String, dynamic> billingInfo = orderData['billing'] ?? {};
    final String billingAddress =
        '''
${billingInfo['first_name'] ?? ''} ${billingInfo['last_name'] ?? ''}
${billingInfo['address_1'] ?? ''}, ${billingInfo['city'] ?? ''}
${billingInfo['state'] ?? ''}, ${billingInfo['country'] ?? ''}
''';

    final List<dynamic> lineItems = orderData['line_items'] ?? [];

    void navigateToHome() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
        title: Text(
          l10n.order_confirmed,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationHeader(l10n),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.order_details),
            _buildCombinedDetailsCard(
              l10n: l10n,
              orderId: orderId.toString(),
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
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(child: _buildTrackOrderButton(context, orderData, l10n)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContinueShoppingButton(
                  context,
                  navigateToHome,
                  l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationHeader(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange,
            child: Icon(Icons.check, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.thank_you_order,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.order_placed_successfully,
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
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.black54)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedDetailsCard({
    required AppLocalizations l10n,
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
            _buildDetailRow(l10n.order_id_label, '#$orderId'),
            _buildDetailRow(l10n.date_label, dateCreated),
            _buildDetailRow(l10n.payment_method_label, paymentMethod),
            _buildDetailRow(
              l10n.status_label,
              status.toUpperCase(),
              valueColor: Colors.orange,
            ),
            const Divider(height: 24, thickness: 1),
            Text(
              l10n.shipping_address_label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(billingAddress, style: GoogleFonts.poppins(height: 1.5)),
            const Divider(height: 24, thickness: 1),
            Text(
              l10n.order_summary_label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
                    Expanded(
                      child: Text(
                        '$name (x$quantity)',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    Row(
                      children: [
                        if (currencyImageUrl != null)
                          Image.network(
                            currencyImageUrl,
                            height: 16,
                            errorBuilder: (c, o, s) => const SizedBox(),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          double.tryParse(itemTotal)?.toStringAsFixed(2) ??
                              '0.00',
                          style: GoogleFonts.poppins(),
                        ),
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
                Text(
                  l10n.total_label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    if (currencyImageUrl != null)
                      Image.network(
                        currencyImageUrl,
                        height: 20,
                        errorBuilder: (c, o, s) => const SizedBox(),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      totalAmount.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueShoppingButton(
    BuildContext context,
    VoidCallback onPressed,
    AppLocalizations l10n,
  ) {
    return _buildBaseActionButton(
      onPressed: onPressed,
      label: l10n.continue_shopping,
      icon: Icons.shopping_bag_outlined,
      isPrimary: false,
    );
  }

  Widget _buildTrackOrderButton(
    BuildContext context,
    Map<String, dynamic> orderData,
    AppLocalizations l10n,
  ) {
    return _buildBaseActionButton(
      onPressed: () {
        final order = Order.fromJson(orderData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(order: order),
          ),
        );
      },
      label: l10n.track_btn,
      icon: Icons.local_shipping_outlined,
      isPrimary: true,
    );
  }

  Widget _buildBaseActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.orange : Colors.grey[200],
        foregroundColor: isPrimary ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
