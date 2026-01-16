
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/login_screen.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/checkout_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/wishlist_provider.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/signup_screen.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final wooCommerceService = WooCommerceService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider(wooCommerceService)),
        ChangeNotifierProxyProvider<AuthProvider, CheckoutProvider>(
          create: (_) => CheckoutProvider(null),
          update: (_, auth, previous) => CheckoutProvider(auth),
        ),
      ],
      child: MaterialApp(
        title: 'UCP Pharmacy',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginWrapper(),
          '/home': (context) => const HomeScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case AuthStatus.uninitialized:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.orange)),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginWrapper();
    }
  }
}

class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LoginScreen(),
          ),
        ),
      ),
    );
  }
}
