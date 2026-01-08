
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/language_selection_screen.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/wishlist_provider.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:provider/provider.dart';

void main() {
  // Ensure the binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider()),
        ChangeNotifierProvider(
          create: (context) => CurrencyProvider(WooCommerceService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const LanguageSelectionScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'UCP',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Pharmacy | صيدلية',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
