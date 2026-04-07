import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:myapp/services/meta_events_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.upcA, BarcodeFormat.upcE, BarcodeFormat.code128, BarcodeFormat.qrCode],
  );
  bool isDetected = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isDetected) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => isDetected = true);
        MetaEventsService().logBarcodeScan(code);
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            size: size,
            painter: ScannerOverlayPainter(
              scanAreaSize: scanAreaSize,
              animation: _animationController,
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'مسح الباركود',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 48), // To balance the row alignment
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'قم بتوجيه الكاميرا نحو الباركود لمسحه',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.flash_on,
                      label: 'الفلاش',
                      onTap: () => controller.toggleTorch(),
                    ),
                    _buildOptionButton(
                      icon: Icons.flip_camera_android,
                      label: 'الكاميرا',
                      onTap: () => controller.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Animation<double> animation;

  ScannerOverlayPainter({required this.scanAreaSize, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Central cutout
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dark overlay with hole
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.7);
    final path = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, backgroundPaint);

    // Corner Frames Details
    final framePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
      
    const cornerLength = 40.0;
    final r = scanRect;

    // Top Left
    canvas.drawPath(Path()..moveTo(r.left, r.top + cornerLength)..lineTo(r.left, r.top)..lineTo(r.left + cornerLength, r.top), framePaint);
    // Top Right
    canvas.drawPath(Path()..moveTo(r.right - cornerLength, r.top)..lineTo(r.right, r.top)..lineTo(r.right, r.top + cornerLength), framePaint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(r.left, r.bottom - cornerLength)..lineTo(r.left, r.bottom)..lineTo(r.left + cornerLength, r.bottom), framePaint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(r.right - cornerLength, r.bottom)..lineTo(r.right, r.bottom)..lineTo(r.right, r.bottom - cornerLength), framePaint);

    // Animated Scanning Line
    final lineY = r.top + 10 + ((r.height - 20) * animation.value);
    final linePaint = Paint()
      ..color = Colors.orange.withOpacity(0.8)
      ..strokeWidth = 3.0;

    // Line Shadow/Glow effect
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.4)
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    canvas.drawLine(Offset(r.left + 15, lineY), Offset(r.right - 15, lineY), glowPaint);
    canvas.drawLine(Offset(r.left + 15, lineY), Offset(r.right - 15, lineY), linePaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value || oldDelegate.scanAreaSize != scanAreaSize;
  }
}
