
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import './self_care_screen.dart';
import 'widgets/category_banner.dart';

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
                  child: CategoryBanner(
                    title: 'Self Care',
                    subtitle: 'Shop now',
                    videoAsset: 'assets/home/self-care.mp4',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SelfCareScreen()),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: CategoryBanner(
                    title: 'Medicines',
                    subtitle: 'Shop now',
                    videoAsset: 'assets/home/medicines.mp4',
                    showFloatingIcon: true,
                    onTap: () {
                      // TODO: Implement navigation to medicines screen.
                    },
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
                    suffixIcon:
                        Icon(Icons.photo_camera_back, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
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
}
