
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum DeliveryOptions { home, pickup }
enum PaymentMethods { visa, mastercard, paypal }

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryOptions _deliveryOption = DeliveryOptions.home;
  PaymentMethods? _selectedPaymentMethod = PaymentMethods.visa;
  int _selectedCardIndex = 0; // To track selected saved card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoTile('Phone Number', Icons.phone_android_outlined),
              const SizedBox(height: 12),
              _buildInfoTile('Deliver To', Icons.location_on_outlined, isSelected: true),
              const SizedBox(height: 24),
              _buildDeliveryOptions(),
              const SizedBox(height: 24),
              Text(
                'Payment Methods',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethods(),
              const SizedBox(height: 24),
              _buildPaymentForm(),
              const SizedBox(height: 24),
              Text(
                'Saved Cards',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildSavedCard(
                index: 0,
                icon: FontAwesomeIcons.ccVisa,
                cardInfo: 'Visa Ending in 2567',
                expiry: 'Expiry 03/2028',
                iconColor: const Color(0xFF1A1F71),
              ),
              const SizedBox(height: 12),
              _buildSavedCard(
                index: 1,
                icon: FontAwesomeIcons.ccMastercard,
                cardInfo: 'Master Card Ending in 8889',
                expiry: 'Expiry 04/2026',
                iconColor: Colors.red,
              ),
              const SizedBox(height: 24),
              _buildAttachPrescription(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoTile(String title, IconData icon, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Row(
      children: [
        Radio<DeliveryOptions>(
          value: DeliveryOptions.home,
          groupValue: _deliveryOption,
          onChanged: (DeliveryOptions? value) {
            setState(() {
              _deliveryOption = value!;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        Text('Home Delivery', style: GoogleFonts.poppins()),
        const SizedBox(width: 24),
        Radio<DeliveryOptions>(
          value: DeliveryOptions.pickup,
          groupValue: _deliveryOption,
          onChanged: (DeliveryOptions? value) {
            setState(() {
              _deliveryOption = value!;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        Text('Pharmacy Pickup', style: GoogleFonts.poppins()),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPaymentMethodCard(
          method: PaymentMethods.visa,
          icon: FontAwesomeIcons.ccVisa,
          iconColor: const Color(0xFF1A1F71),
        ),
        _buildPaymentMethodCard(
          method: PaymentMethods.mastercard,
          icon: FontAwesomeIcons.ccMastercard,
          iconColor: Colors.red,
        ),
        _buildPaymentMethodCard(
          method: PaymentMethods.paypal,
          icon: FontAwesomeIcons.ccPaypal,
          iconColor: Colors.blue.shade800,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({required PaymentMethods method, required IconData icon, required Color iconColor}) {
    bool isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.orange.shade700, width: 2) : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 35,
            color: iconColor,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentForm() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildTextField('Card Holder Name', 'Mohamed Hamed')),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: _buildTextField('CVV', '123', isNumeric: true)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _buildTextField('Card Number', '1234 **** **** ****', isNumeric: true)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: _buildTextField('Expire Date', '03/2025')),
        ],
      ),
    ],
  );
}


  Widget _buildTextField(String label, String hint, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: hint,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCard({required int index, required IconData icon, required String cardInfo, required String expiry, required Color iconColor}) {
    bool isSelected = _selectedCardIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.orange.shade700, width: 2) : Border.all(color: Colors.grey.shade300),
           boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            FaIcon(icon, color: iconColor, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardInfo, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(expiry, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Spacer(),
            if (isSelected)
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.orange.shade700,
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttachPrescription() {
    return ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: Text(
          'Attach a Prescriptions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {
               Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Continue shopping',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Handle Pay Now
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            label: Text(
              'Pay Now  350EGP',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        ],
      ),
    );
  }
}
