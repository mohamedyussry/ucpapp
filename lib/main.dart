import 'l10n/generated/app_localizations.dart';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/login_screen.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/checkout_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/loyalty_provider.dart';
import 'package:myapp/providers/wishlist_provider.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/signup_screen.dart';
import 'package:myapp/screens/phone_login_screen.dart';
import 'package:myapp/screens/otp_verification_screen.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:myapp/providers/language_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    developer.log("Main: Firebase initialization error: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();

  // Initialize notifications (Non-blocking to prevent splash hang)
  NotificationService().initialize().catchError((e) {
    developer.log("Main: NotificationService initialization error: $e");
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );

  // Explicitly remove splash screen after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final wooCommerceService = WooCommerceService();
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(wooCommerceService),
        ),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CheckoutProvider>(
          create: (_) => CheckoutProvider(null),
          update: (_, auth, previous) => CheckoutProvider(auth),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'UCP Pharmacy',
        locale: languageProvider.appLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) =>
              const LoginWrapper(), // Keep for backward compatibility if needed
          '/email_login': (context) =>
              const LoginWrapper(), // New explicit route
          '/home': (context) => const HomeScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/phone_login': (context) => const PhoneLoginScreen(),
          '/otp_verification': (context) => const OtpVerificationScreen(),
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
        // Changed default to PhoneLoginScreen
        return const PhoneLoginScreen();
    }
  }
}

class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
