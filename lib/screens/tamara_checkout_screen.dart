import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as developer;

class TamaraCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;

  const TamaraCheckoutScreen({super.key, required this.checkoutUrl});

  @override
  State<TamaraCheckoutScreen> createState() => _TamaraCheckoutScreenState();
}

class _TamaraCheckoutScreenState extends State<TamaraCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            developer.log('TAMARA: Page started: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            developer.log('TAMARA: Page finished: $url');
            setState(() {
              _isLoading = false;
            });

            // Check if we are on one of the callback URLs
            if (url.contains('tamara/success')) {
              developer.log('TAMARA: Payment Success detected');
              Navigator.pop(context, true);
            } else if (url.contains('tamara/failure') ||
                url.contains('tamara/cancel')) {
              developer.log('TAMARA: Payment Failed/Cancelled detected');
              Navigator.pop(context, false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            developer.log('TAMARA: Webview error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            developer.log('TAMARA: Navigation request to: ${request.url}');
            if (request.url.contains('tamara/success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('tamara/failure') ||
                request.url.contains('tamara/cancel')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tamara Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
        ],
      ),
    );
  }
}
