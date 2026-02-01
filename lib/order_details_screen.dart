import 'package:flutter/material.dart';
import 'package:myapp/models/order_model.dart';
import 'l10n/generated/app_localizations.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.order_label} #${order.id}'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cinzel',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.order_details,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cinzel',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(l10n, l10n.order_id_label, '#${order.id}'),
                    _buildDetailRow(
                      l10n,
                      l10n.date_label,
                      '${order.date.day}/${order.date.month}/${order.date.year}',
                    ),
                    _buildDetailRow(
                      l10n,
                      l10n.status_label,
                      order.status.toUpperCase(),
                      statusColor: _getStatusColor(order.status),
                    ),
                    _buildDetailRow(
                      l10n,
                      l10n.total_label,
                      '${order.totalPrice.toStringAsFixed(2)} ${order.currency}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.products_label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cinzel',
              ),
            ),
            const SizedBox(height: 8),
            ...order.productNames.map(
              (productName) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: ListTile(
                  leading: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    AppLocalizations l10n,
    String title,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'processing':
      case 'pending':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
      case 'failed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
