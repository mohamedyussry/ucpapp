import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/order_tracking_screen.dart';
import 'package:myapp/services/woocommerce_service.dart';
import '../l10n/generated/app_localizations.dart';

class OrderTrackingLoaderScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingLoaderScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingLoaderScreen> createState() =>
      _OrderTrackingLoaderScreenState();
}

class _OrderTrackingLoaderScreenState extends State<OrderTrackingLoaderScreen> {
  final WooCommerceService _wooService = WooCommerceService();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _wooService.getOrderById(widget.orderId);
      if (order != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(order: order),
          ),
        );
      } else if (mounted) {
        setState(() => _hasError = true);
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.order_number(widget.orderId),
          style: const TextStyle(color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    l10n.err_load_order_details,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.go_back),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    l10n.loading_order_tracking,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
