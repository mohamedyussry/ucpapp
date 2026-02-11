import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:myapp/cart_screen.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/models/order_model.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/order_details_screen.dart';
import 'package:myapp/order_tracking_screen.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n/generated/app_localizations.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  MyOrdersScreenState createState() => MyOrdersScreenState();
}

class MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WooCommerceService _wooCommerceService = WooCommerceService();
  bool _isLoading = true;
  String? _errorMessage;

  List<Order> _ongoingOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // Add listener to rebuild the UI when tab changes to update button styles
    _tabController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Clear previous lists to ensure fresh data
      _ongoingOrders = [];
      _completedOrders = [];
      _cancelledOrders = [];
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    List<Map<String, dynamic>> wooOrdersData = [];

    try {
      if (authProvider.status == AuthStatus.authenticated &&
          authProvider.customer != null) {
        developer.log(
          'Fetching fresh orders for Customer ID: ${authProvider.customer!.id}',
        );
        wooOrdersData = await _wooCommerceService.getOrders(
          customerId: authProvider.customer!.id,
        );
      } else {
        final box = await Hive.openBox('guest_order_ids');
        final List<int> orderIds = (box.get('ids') as List<dynamic>? ?? [])
            .cast<int>();

        if (orderIds.isEmpty) {
          developer.log('No guest order IDs found in Hive.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        developer.log('Fetching fresh orders for Guest Order IDs: $orderIds');
        wooOrdersData = await _wooCommerceService.getOrders(orderIds: orderIds);
      }

      developer.log('API Response: Received ${wooOrdersData.length} orders.');

      if (wooOrdersData.isNotEmpty) {
        final List<Order> allOrders = wooOrdersData
            .map((data) => Order.fromJson(data))
            .toList();

        setState(() {
          _ongoingOrders = allOrders.where((o) {
            final status = o.status.toLowerCase();
            return status == 'processing' ||
                status == 'pending' ||
                status == 'on-hold' ||
                status == 'prepared';
          }).toList();

          _completedOrders = allOrders
              .where((o) => o.status.toLowerCase() == 'completed')
              .toList();

          _cancelledOrders = allOrders.where((o) {
            final status = o.status.toLowerCase();
            return status == 'cancelled' ||
                status == 'failed' ||
                status == 'refunded';
          }).toList();

          developer.log(
            'Orders sorted. Ongoing: ${_ongoingOrders.length}, Completed: ${_completedOrders.length}, Cancelled: ${_cancelledOrders.length}',
          );
        });
      } else {
        developer.log('No orders returned from API.');
      }
    } catch (e, s) {
      developer.log('Error fetching orders', error: e, stackTrace: s);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.err_loading_orders(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
    );
  }

  void _navigateToTracking(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(order: order),
      ),
    );
  }

  Future<void> _orderAgain(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    if (order.productIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.err_no_products_reorder)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch products by IDs
      final List<WooProduct> products = await _wooCommerceService.getProducts(
        include: order.productIds,
      );

      if (!mounted) return;

      if (products.isNotEmpty) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        for (var product in products) {
          cartProvider.addItem(product);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.msg_products_added_cart(products.length)),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Cart
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.err_products_not_found)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.err_reordering(e))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Text(
          l10n.my_orders,
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -- NEW: Custom Tab Buttons --
            _buildCustomTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildShimmerEffect()
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                            onPressed: _fetchOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersTab(
                          _ongoingOrders,
                          _buildOngoingOrderCard,
                          l10n.no_ongoing_orders,
                        ),
                        _buildOrdersTab(
                          _completedOrders,
                          _buildCompletedOrderCard,
                          l10n.no_completed_orders,
                        ),
                        _buildOrdersTab(
                          _cancelledOrders,
                          _buildCancelledOrderCard,
                          l10n.no_cancelled_orders,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // -- NEW: Widget for the custom tab buttons --
  Widget _buildCustomTabBar() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTabButton(0, l10n.tab_ongoing),
        _buildTabButton(1, l10n.tab_completed),
        _buildTabButton(2, l10n.tab_cancelled),
      ],
    );
  }

  // -- NEW: Widget for individual tab button --
  Widget _buildTabButton(int index, String title) {
    bool isSelected = _tabController.index == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: isSelected
            ? ElevatedButton(
                onPressed: () => _tabController.animateTo(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 4,
                  shadowColor: Colors.orange.withValues(alpha: 0.4),
                ),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : OutlinedButton(
                onPressed: () => _tabController.animateTo(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(title),
              ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16.0),
        itemCount: 5,
        itemBuilder: (context, index) => _buildPlaceholderOrderCard(),
      ),
    );
  }

  Widget _buildPlaceholderOrderCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.grey.withAlpha(51),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 14, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 120, height: 14, color: Colors.white),
                ],
              ),
            ),
            Column(
              children: [
                Container(width: 80, height: 36, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 80, height: 36, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(
    List<Order> orders,
    Widget Function(Order) cardBuilder,
    String noOrdersMessage,
  ) {
    if (_isLoading) return _buildShimmerEffect();
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              noOrdersMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16.0),
        physics:
            const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return cardBuilder(order);
        },
      ),
    );
  }

  Widget _buildOngoingOrderCard(Order order) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.grey.withAlpha(51),
      child: InkWell(
        onTap: () => _navigateToDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFD81B60),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.productNames.join(', '),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.order_number(order.id),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.price_label(
                        order.totalPrice.toStringAsFixed(2),
                        order.currency,
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _navigateToTracking(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: Text(
                        l10n.track_btn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetails(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF3E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.details_btn,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedOrderCard(Order order) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.grey.withAlpha(51),
      child: InkWell(
        onTap: () => _navigateToDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productNames.join(', '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.order_number(order.id),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.price_label(
                            order.totalPrice.toStringAsFixed(2),
                            order.currency,
                          ),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.view_details_link,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _orderAgain(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(
                        l10n.order_again_btn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.rate_label,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => const Icon(
                        Icons.star_border,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledOrderCard(Order order) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.grey.withAlpha(51),
      child: InkWell(
        onTap: () => _navigateToDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productNames.join(', '),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.order_number(order.id),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.price_label(
                        order.totalPrice.toStringAsFixed(2),
                        order.currency,
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
