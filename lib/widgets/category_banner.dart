import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

class CategoryBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? videoAsset;
  final bool showFloatingIcon;
  final VoidCallback? onTap;
  final VideoPlayerController? controller; // Accept an external controller

  const CategoryBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.videoAsset,
    this.showFloatingIcon = false,
    this.onTap,
    this.controller, // Make it nullable
  }) : assert(controller != null || videoAsset != null,
            'Either controller or videoAsset must be provided.');

  @override
  State<CategoryBanner> createState() => _CategoryBannerState();
}

class _CategoryBannerState extends State<CategoryBanner> {
  late VideoPlayerController _controller;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      // Use the external controller if it's provided
      _controller = widget.controller!;
      _isExternalController = true;
    } else {
      // Otherwise, create and manage the controller internally
      _isExternalController = false;
      _controller = VideoPlayerController.asset(widget.videoAsset!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller.play();
            _controller.setLooping(true);
            _controller.setVolume(0);
          }
        });
    }
  }

  @override
  void didUpdateWidget(covariant CategoryBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller is managed internally and the asset changes, update it.
    if (!_isExternalController && widget.videoAsset != oldWidget.videoAsset) {
      _controller.dispose();
      _controller = VideoPlayerController.asset(widget.videoAsset!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller.play();
            _controller.setLooping(true);
            _controller.setVolume(0);
          }
        });
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if it was created and managed internally
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player
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
              // Overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Icon
              if (widget.showFloatingIcon)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(204),
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
      ),
    );
  }
}
