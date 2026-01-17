import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:myapp/products_screen.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import './self_care_screen.dart';
import 'widgets/category_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _selfCareController;
  late VideoPlayerController _medicinesController;
  late Future<void> _initializeVideoPlayersFuture;

  @override
  void initState() {
    super.initState();
    _selfCareController = VideoPlayerController.asset('assets/home/self-care.mp4');
    _medicinesController = VideoPlayerController.asset('assets/home/medicines.mp4');

    // This future will complete once both controllers are initialized.
    _initializeVideoPlayersFuture = Future.wait([
      _selfCareController.initialize(),
      _medicinesController.initialize(),
    ]).then((_) {
      // This block executes ONCE after both videos are successfully initialized.
      // We play the videos here to ensure it's not called during a rebuild.
      _selfCareController
        ..play()
        ..setLooping(true)
        ..setVolume(0);

      _medicinesController
        ..play()
        ..setLooping(true)
        ..setVolume(0);
    });
  }

  @override
  void dispose() {
    _selfCareController.dispose();
    _medicinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: _initializeVideoPlayersFuture,
          builder: (context, snapshot) {
            // While the future is running (initializing), show a loading indicator.
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }
            // If an error occurred during initialization, display it.
            if (snapshot.hasError) {
              return Center(
                child: Text('Error initializing videos: ${snapshot.error}'),
              );
            }
            // Once initialization is complete (with or without error, handled above),
            // build the UI. The videos are already playing due to the .then() block.
            return Column(
              children: [
                Expanded(
                  child: CategoryBanner(
                    key: const ValueKey('self_care_banner'), // Added key for stability
                    title: 'Self Care',
                    subtitle: 'Shop now',
                    controller: _selfCareController,
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
                    key: const ValueKey('medicines_banner'), // Added key for stability
                    title: 'Medicines',
                    subtitle: 'Shop now',
                    controller: _medicinesController,
                    showFloatingIcon: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProductsScreen(category: 'Medicine'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}
