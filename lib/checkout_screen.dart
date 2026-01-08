import 'package:flutter/material.dart';
import 'package:myapp/payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryOption = 'Home Delivery';
  int _selectedPaymentMethod = 0;
  int _selectedSavedCard = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shopping_bag_outlined, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(icon: Icons.phone_outlined, text: 'Phone Number'),
            const SizedBox(height: 10),
            _buildInfoRow(icon: Icons.location_on_outlined, text: 'Deliver To', isCard: true),
            const SizedBox(height: 20),
            _buildDeliveryOptions(),
            const SizedBox(height: 20),
            const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _buildPaymentMethods(),
            const SizedBox(height: 20),
            _buildCardForm(),
            const SizedBox(height: 20),
            const Text('Saved Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _buildSavedCards(),
            const SizedBox(height: 20),
            _buildAttachPrescriptionButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text, bool isCard = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: isCard
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            )
          : null,
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      children: [
        RadioMenuButton<String>(
          value: 'Home Delivery',
          groupValue: _deliveryOption,
          onChanged: (value) => setState(() => _deliveryOption = value!),
          child: const Text('Home Delivery'),
        ),
        RadioMenuButton<String>(
          value: 'Pharmacy Pickup',
          groupValue: _deliveryOption,
          onChanged: (value) => setState(() => _deliveryOption = value!),
          child: const Text('Pharmacy Pickup'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPaymentMethod(0, 'images/visa.png'),
        _buildPaymentMethod(1, 'images/mastercard.png'),
        _buildPaymentMethod(2, 'images/paypal.png'),
      ],
    );
  }

  Widget _buildPaymentMethod(int index, String imagePath) {
    bool isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withAlpha(76),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Image.asset(imagePath, height: 24),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Card Holder Name', 'Mohamed Hamed')),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField('CVV', '123')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField('Card Number', '1234 **** **** ****')),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField('Expire Date', '03/2025')),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 5),
        TextField(
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCards() {
    return Column(
      children: [
        _buildSavedCard(
          index: 0,
          imagePath: 'images/visa.png',
          cardInfo: 'Visa Ending in 2567',
          expiry: 'Expiry 03/2028',
        ),
        const SizedBox(height: 10),
        _buildSavedCard(
          index: 1,
          imagePath: 'images/mastercard.png',
          cardInfo: 'Master Card Ending in 8889',
          expiry: 'Expiry 04/2026',
        ),
      ],
    );
  }

  Widget _buildSavedCard({required int index, required String imagePath, required String cardInfo, required String expiry}) {
    bool isSelected = _selectedSavedCard == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSavedCard = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withAlpha(25) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(imagePath, height: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardInfo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(expiry, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachPrescriptionButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
      label: const Text('Attach a Prescriptions', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue shopping', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.white),
                SizedBox(width: 5),
                Text('Pay Now', style: TextStyle(color: Colors.white)),
                SizedBox(width: 5),
                Text('350EGP', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
