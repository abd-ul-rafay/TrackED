import 'package:tracked/screens/auth_screens/auth.dart';
import 'package:tracked/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackED',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      theme: lightThemeData(context),
      darkTheme: darkThemeData(context),

      home: const Auth(), // it will check whether the user is logged in or not
    );
  }
}
