
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Back',
              ),
            ),
          ),
        ),
        title: Text('Profile',
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          if (authProvider.status == AuthStatus.authenticated)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black, size: 20),
                    onPressed: () => authProvider.logout(),
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, authProvider),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 4),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
    switch (authProvider.status) {
      case AuthStatus.uninitialized:
        return const Center(child: CircularProgressIndicator(color: Colors.orange));
      case AuthStatus.authenticated:
        if (authProvider.customer != null) {
          return _buildProfileView(authProvider.customer!);
        } else {
          // This should ideally not happen if status is authenticated
          return _buildLoginView(context);
        }
      case AuthStatus.unauthenticated:
        return _buildLoginView(context);
    }
  }

  Widget _buildLoginView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LoginScreen(),
        ),
      ),
    );
  }

  Widget _buildProfileView(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(customer.avatarUrl),
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text(
          '${customer.firstName} ${customer.lastName}',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          customer.username,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection('My Account', [
                    _buildProfileOption(icon: FontAwesomeIcons.user, title: 'Personal Information'),
                    _buildProfileOption(icon: FontAwesomeIcons.box, title: 'My Orders'),
                    _buildProfileOption(icon: FontAwesomeIcons.arrowsRotate, title: 'Return/Exchange'),
                    _buildProfileOption(icon: FontAwesomeIcons.percent, title: 'My Points'),
                    _buildProfileOption(
                        icon: FontAwesomeIcons.globe,
                        title: 'Language',
                        trailing: Text('English (US)', style: GoogleFonts.poppins(color: Colors.grey.shade600))),
                    _buildProfileOption(icon: FontAwesomeIcons.circleQuestion, title: 'About App'),
                    _buildProfileOption(icon: FontAwesomeIcons.headset, title: 'Help & Support'),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Notification', [
                    _buildNotificationOption(title: 'Push Notification', value: true),
                    _buildNotificationOption(title: 'Promotional Notification', value: false),
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10, top: 10),
            child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: children,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: FaIcon(icon, color: Colors.black87, size: 20),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildNotificationOption({required String title, required bool value}) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16)),
      value: value,
      onChanged: (bool newValue) {},
      activeTrackColor: Colors.orange[200],
      activeThumbColor: Colors.orange,
    );
  }
}
