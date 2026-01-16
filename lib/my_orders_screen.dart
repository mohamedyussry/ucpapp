
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:myapp/cart_screen.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/models/order_model.dart';
import 'package:myapp/order_details_screen.dart';
import 'package:myapp/order_tracking_screen.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  MyOrdersScreenState createState() => MyOrdersScreenState();
}

class MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
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
    // Defer fetching until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    List<Map<String, dynamic>> wooOrdersData = [];

    try {
      if (authProvider.status == AuthStatus.authenticated && authProvider.customer != null) {
        // Fetch orders for logged-in user
        wooOrdersData = await _wooCommerceService.getOrders(customerId: authProvider.customer!.id);
      } else {
        // Fetch orders for guest user
        final box = await Hive.openBox('guest_order_ids');
        final List<int> orderIds = (box.get('ids') as List<dynamic>? ?? []).cast<int>();

        if (orderIds.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        wooOrdersData = await _wooCommerceService.getOrders(orderIds: orderIds);
      }

      if (wooOrdersData.isNotEmpty) {
        final List<Order> allOrders = wooOrdersData.map((data) => Order.fromJson(data)).toList();

        setState(() {
          _ongoingOrders = allOrders.where((o) => o.status == 'processing' || o.status == 'pending').toList();
          _completedOrders = allOrders.where((o) => o.status == 'completed').toList();
          _cancelledOrders = allOrders.where((o) => o.status == 'cancelled' || o.status == 'failed' || o.status == 'refunded').toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order),
      ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'My orders',
          style: TextStyle(
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
            Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildShimmerEffect()
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                onPressed: _fetchOrders,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              )
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersTab(_ongoingOrders, _buildOngoingOrderCard, "No ongoing orders yet."),
                            _buildOrdersTab(_completedOrders, _buildCompletedOrderCard, "No completed orders yet."),
                            _buildOrdersTab(_cancelledOrders, _buildCancelledOrderCard, "No cancelled orders yet."),
                          ],
                        ),
            ),
          ],
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
        itemCount: 5, // Display 5 shimmer cards
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
                  Container(width: double.infinity, height: 18, color: Colors.white),
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(List<Order> orders, Widget Function(Order) cardBuilder, String noOrdersMessage) {
    if (_isLoading) return _buildShimmerEffect();
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(noOrdersMessage, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return cardBuilder(order);
      },
    );
  }

  Widget _buildOngoingOrderCard(Order order) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    Text(order.productNames.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Order #${order.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Price: ${order.totalPrice.toStringAsFixed(2)} ${order.currency}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Track', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetails(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF3E0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        elevation: 0,
                      ),
                      child: const Text('Details', style: TextStyle(color: Colors.black87, fontSize: 12)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedOrderCard(Order order) {
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
                        Text(order.productNames.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Order ID: ${order.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Price: ${order.totalPrice.toStringAsFixed(2)} ${order.currency}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('View details', style: TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Order again', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rate', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  Row(
                    children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.grey, size: 20)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledOrderCard(Order order) {
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
                    Text(order.productNames.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Order ID: ${order.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Price: ${order.totalPrice.toStringAsFixed(2)} ${order.currency}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Status: ${order.status.toUpperCase()}', style: const TextStyle(color: Colors.red, fontSize: 12)),
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
