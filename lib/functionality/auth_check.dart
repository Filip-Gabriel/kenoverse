// A wrapper widget that listens to the Firebase auth state.
// It directs users to either the MainScreen (if logged in) or the LoginScreen.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kenoverse/screens/main_screen.dart';
import 'package:kenoverse/screens/login_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
