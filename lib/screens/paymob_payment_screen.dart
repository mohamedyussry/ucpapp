import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
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
        'https://ksa.paymob.com/unifiedcheckout/?publicKey=${app_config.Config.paymobPublicKey}&clientSecret=${widget.paymentToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            developer.log('WebView navigating to: $url');

            if (url.contains('success=true') ||
                url.contains('payment-success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            } else if (url.contains('success=false')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
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
