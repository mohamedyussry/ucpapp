import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import './self_care_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content area below header
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SelfCareScreen()),
                      );
                    },
                    child: _buildCategoryCard(
                      context,
                      'Self Care',
                      'Shop now',
                      'https://images.unsplash.com/photo-1580221367657-26a9134ce1fa?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&id=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                    ),
                  ),
                ),
                Expanded(
                  child: _buildCategoryCard(
                    context,
                    'Medicines',
                    'Shop now',
                    'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=2030&auto=format&fit=crop&ixlib=rb-4.0.3&id=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                    showFloatingIcon: true,
                  ),
                ),
              ],
            ),
          ),
          // Custom Header
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'What can we help you find?',
                    hintStyle: GoogleFonts.lato(color: Colors.grey.shade600),
                    suffixIcon: Icon(Icons.photo_camera_back, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 20),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.tableCellsLarge, size: 20),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.rotate, size: 20),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.heart, size: 20),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.user, size: 20),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.lato(),
          backgroundColor: Colors.white,
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, String title, String subtitle, String imageUrl,
      {bool showFloatingIcon = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (showFloatingIcon)
              Positioned(
                bottom: 40,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.8),
                  radius: 30,
                  child: const FaIcon(
                    FontAwesomeIcons.pills,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
