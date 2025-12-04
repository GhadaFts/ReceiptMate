import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projet_flutter/pages/SmartHomePage.dart';
import 'auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/favorites_page.dart';
import 'pages/pantry_page.dart';
import 'pages/profile_page.dart'; //
import 'pages/main_navigation_page.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your config
  await Firebase.initializeApp(
    options: FirebaseOptions(
      projectId: Config.projectId,
      appId: Config.appId,
      apiKey: Config.apiKey,
      messagingSenderId: Config.messagingSenderId,
      storageBucket: Config.storageBucket,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipe Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/smartHome': (context) => const SmartHomePage(),

        // ✅ NOUVELLE ROUTE PRINCIPALE
        '/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return MainNavigationPage(
            initialIndex: args is int ? args : 0,
          );
        },

        // Routes individuelles (compatibilité)
        '/home': (context) => const MainNavigationPage(initialIndex: 0),
        '/pantry': (context) => const MainNavigationPage(initialIndex: 1),
        '/favoris': (context) => const MainNavigationPage(initialIndex: 2),
        '/profil': (context) => const MainNavigationPage(initialIndex: 3),
      },
    );
  }
}