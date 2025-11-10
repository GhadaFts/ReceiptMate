import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/landing_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show landing page while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LandingPage(); // Show landing page during initial check
        }

        // User is not logged in - show landing page (which will redirect to login)
        if (!snapshot.hasData) {
          return const LandingPage();
        }

        // User is logged in - check if onboarding is completed
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // User document doesn't exist, go to onboarding
              return const OnboardingPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final onboardingCompleted = userData['onboardingCompleted'] ?? false;

            if (!onboardingCompleted) {
              return const OnboardingPage();
            }

            return const HomePage();
          },
        );
      },
    );
  }
}