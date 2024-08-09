import 'package:tracked/screens/home.dart';
import 'package:tracked/screens/auth_screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/login_timestamp.dart';

class Auth extends StatelessWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: _checkLoginExpiry(),
              builder: (context, AsyncSnapshot<bool> loginExpirySnapshot) {
                if (loginExpirySnapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while checking login expiry
                  return const Center(child: CircularProgressIndicator());
                }

                if (loginExpirySnapshot.data == true) {
                  // If the login is expired, sign out the user and show the login screen
                  FirebaseAuth.instance.signOut();
                  return const LoginScreen();
                } else {
                  // If the login is still valid, show the home screen
                  return const HomeScreen();
                }
              },
            );
          } else {
            return const LoginScreen();
          }
        }
    );
  }

  Future<bool> _checkLoginExpiry() async {
    LoginTimestamp loginTimestamp = LoginTimestamp();
    const double periodInDays = 30; // Set your desired period here
    return await loginTimestamp.isLoginExpired(periodInDays);
  }
}
