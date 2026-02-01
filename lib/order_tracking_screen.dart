import 'package:flutter/material.dart';
import 'package:myapp/models/order_model.dart';
import 'l10n/generated/app_localizations.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  String _getTrackingImage(String status) {
    switch (status.toLowerCase()) {
      // Use toLowerCase for case-insensitivity
      case 'pending':
      case 'processing':
        return 'assets/images/track_received.png';
      case 'on-hold':
      case 'shipped':
      case 'prepared': // Added 'prepared' status for stage 2
        return 'assets/images/track_on_the_way.png';
      case 'completed':
        return 'assets/images/track_delivered.png';
      default:
        return 'assets/images/track_received.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.order_tracking_title,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cinzel',
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _getTrackingImage(order.status),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Text(
                    l10n.image_not_found,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStatusCard(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.order_id_colon,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimelineTracker(l10n),
        ],
      ),
    );
  }

  Widget _buildTimelineTracker(AppLocalizations l10n) {
    final status = order.status
        .toLowerCase(); // Use a local, lowercase status for reliable comparison

    // Define which statuses belong to which stage
    const receivedStatuses = ['pending', 'processing'];
    const onTheWayStatuses = ['shipped', 'on-hold', 'prepared'];
    const deliveredStatuses = ['completed'];

    // Determine if stages are completed
    bool isReceivedCompleted =
        true; // First step is always considered completed once order is made
    bool isOnTheWayCompleted =
        onTheWayStatuses.contains(status) || deliveredStatuses.contains(status);
    bool isDeliveredCompleted = deliveredStatuses.contains(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimelineStep(
          icon: Icons.access_time,
          label: l10n.received_status,
          time: '${order.date.hour}:${order.date.minute}',
          isActive: receivedStatuses.contains(status),
          isCompleted: isReceivedCompleted,
        ),
        _buildTimelineConnector(isCompleted: isOnTheWayCompleted),
        _buildTimelineStep(
          icon: Icons.local_shipping_outlined,
          label: l10n.on_the_way_status,
          time: '--:--',
          isActive: onTheWayStatuses.contains(status),
          isCompleted: isOnTheWayCompleted,
        ),
        _buildTimelineConnector(isCompleted: isDeliveredCompleted),
        _buildTimelineStep(
          icon: Icons.home_outlined,
          label: l10n.delivered_status,
          time: '--:--',
          isActive: isDeliveredCompleted,
          isCompleted: isDeliveredCompleted,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String label,
    required String time,
    bool isActive = false,
    bool isCompleted = false,
  }) {
    final Color activeColor = Colors.orange.shade700;
    final Color inactiveColor = Colors.grey.shade400;
    final Color stepColor = isCompleted ? activeColor : inactiveColor;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(102),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : stepColor,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.black87 : Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimelineConnector({bool isCompleted = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 40),
        color: isCompleted ? Colors.orange.shade700 : Colors.grey.shade400,
      ),
    );
  }
}
