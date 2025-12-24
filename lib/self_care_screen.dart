import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

// A stateful widget to manage the video playback
class VideoBackground extends StatefulWidget {
  final String videoPath;
  final bool isVisible;

  const VideoBackground({super.key, required this.videoPath, this.isVisible = true});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _initializeController();
    }
  }

  void _initializeController() {
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
          _controller.setVolume(0);
        }
      });
  }
  
  @override
  void didUpdateWidget(covariant VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !_initialized) {
      _initializeController();
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || !widget.isVisible) {
      return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  int _bottomNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _bottomNavIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Use AnimatedBuilder for performance
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final animationEndOffset = screenHeight * 0.35;
              
              // Check if the controller is attached before using offset
              final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
              final progress = (offset / animationEndOffset).clamp(0.0, 1.0);

              final herWidth = lerpDouble(screenWidth, screenWidth / 3, progress)!;
              final herLeft = lerpDouble(0, screenWidth / 3, progress)!;

              return _buildAnimatedBackground(progress, screenWidth, screenHeight, herWidth, herLeft);
            },
          ),

          // Dummy scroll view to drive the animation
          ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 1.5),
            ],
          ),

          _buildHeader(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildAnimatedBackground(double progress, double screenWidth, double screenHeight, double herWidth, double herLeft) {
    return Stack(
      children: [
        // HIM Card
        Positioned(
          left: 0,
          width: screenWidth / 3,
          height: screenHeight,
          child: Opacity(
            opacity: progress, // Fade in
            child: _buildCategoryPage(
              'HIM',
              'assets/him.mp4',
              isVisible: progress > 0.1, // Lazy load
            ),
          ),
        ),

        // BABY Card
        Positioned(
          left: screenWidth * 2 / 3,
          width: screenWidth / 3,
          height: screenHeight,
          child: Opacity(
            opacity: progress, // Fade in
            child: _buildCategoryPage(
              'BABY',
              'assets/baby.mp4',
              isVisible: progress > 0.1, // Lazy load
            ),
          ),
        ),

        // HER Card
        Positioned(
          left: herLeft,
          width: herWidth,
          height: screenHeight,
          child: _buildCategoryPage(
            'HER',
            'assets/HER.mp4',
            isVisible: true, // Always visible
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPage(String title, String videoPath, {required bool isVisible}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoBackground(videoPath: videoPath, isVisible: isVisible),
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(height: 2, width: 100, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 140,
        color: Colors.black.withOpacity(0.4),
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
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomNavBar(BuildContext context) {
     return Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house, size: 20), label: 'Home'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.tableCellsLarge, size: 20), label: 'Categories'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.rotate, size: 20), label: 'Orders'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.heart, size: 20), label: 'Favorites'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.user, size: 20), label: 'Profile'),
          ],
          currentIndex: _bottomNavIndex,
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
      );
  }
}
