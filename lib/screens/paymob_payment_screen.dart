import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config.dart' as app_config;
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/generated/app_localizations.dart';

class PaymobPaymentScreen extends StatefulWidget {
  final String paymentToken;

  const PaymobPaymentScreen({super.key, required this.paymentToken});

  @override
  State<PaymobPaymentScreen> createState() => _PaymobPaymentScreenState();
}

class _PaymobPaymentScreenState extends State<PaymobPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final String url =
        'https://ksa.paymob.com/api/acceptance/iframes/${app_config.Config.paymobIframeId}?payment_token=${widget.paymentToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Handle success/failure based on URL params from Paymob return URL
            if (url.contains('success=true')) {
              Navigator.pop(context, true);
            } else if (url.contains('success=false')) {
              Navigator.pop(context, false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Webview error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.payment_title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
