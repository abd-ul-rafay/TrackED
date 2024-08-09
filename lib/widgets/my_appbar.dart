import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as model;
import '../screens/profile_screens/settings.dart';
import '../utils/consts.dart';

PreferredSize myAppBar(
    model.User user, BuildContext context, int pageSelected) {
  String greeting;

  if (DateTime.now().hour >= 5 && DateTime.now().hour < 12) {
    greeting = 'Good Morning,';
  } else if (DateTime.now().hour >= 12 && DateTime.now().hour < 17) {
    greeting = 'Good Afternoon,';
  } else {
    greeting = 'Good Evening,';
  }

  final color = (MediaQuery.of(context).platformBrightness == Brightness.light)
      ? Colors.white
      : myColor;

  return PreferredSize(
    preferredSize: const Size.fromHeight(60.0),
    child: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HELLO! $greeting',
            style: TextStyle(fontSize: 14.0, color: color),
          ),
          Text(
            user.name,
            style: TextStyle(fontSize: 20.0, color: color),
            overflow: TextOverflow.fade,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: pageSelected == 2 // show setting and logout icons in home screen
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              user: user,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.settings,
                          color: color,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Are you sure you want to logout?',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () {
                                      FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Logout')),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
        ),
      ],
    ),
  );
}
