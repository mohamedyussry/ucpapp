import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/products_screen.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryPage(
                    displayTitle: 'HIM',
                    apiCategory: 'For Him',
                    videoAsset: 'assets/him.mp4',
                  ),
                ),
                Expanded(
                  child: _buildCategoryPage(
                    displayTitle: 'HER',
                    apiCategory: 'For Her',
                    videoAsset: 'assets/HER.mp4',
                  ),
                ),
                Expanded(
                  child: _buildCategoryPage(
                    displayTitle: 'BABY',
                    apiCategory: 'For Baby',
                    videoAsset: 'assets/baby.mp4',
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1), // Using the unified widget
    );
  }

  Widget _buildCategoryPage({
    required String displayTitle,
    required String apiCategory,
    required String videoAsset,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsScreen(category: apiCategory),
          ),
        );
      },
      child: _CategoryVideo(videoAsset: videoAsset, title: displayTitle),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 20),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'What can we help you find?',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            suffixIcon: Icon(Icons.image_search_outlined, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
    );
  }
}

class _CategoryVideo extends StatefulWidget {
  final String videoAsset;
  final String title;

  const _CategoryVideo({required this.videoAsset, required this.title});

  @override
  __CategoryVideoState createState() => __CategoryVideoState();
}

class __CategoryVideoState extends State<_CategoryVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
          _controller.setVolume(0);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black, width: 0.5),
          left: BorderSide(color: Colors.black, width: 0.5),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, width: 80, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
