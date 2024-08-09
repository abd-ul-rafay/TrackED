import 'package:flutter/material.dart';
import 'consts.dart';

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
    primaryColor: myColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20.0),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    colorScheme: const ColorScheme.light(
      primary: myColor,
      secondary: myColor,
      onPrimary: Colors.black, // text color
    ),
    textTheme: Theme.of(context).textTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: myColor,
      unselectedItemColor: Colors.grey.withOpacity(0.3),
      selectedIconTheme: const IconThemeData(color: myColor),
      showUnselectedLabels: true,
    ),
  );
}

ThemeData darkThemeData(BuildContext context) {

  return ThemeData.dark().copyWith(
    primaryColor: myColor,
    scaffoldBackgroundColor: const Color(0Xff121212),
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(color: myColor, fontSize: 20.0),
      iconTheme: IconThemeData(color: myColor),
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.grey),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: myColor,
      secondary: myColor,
      onPrimary: Colors.white, // text color
    ),
    textTheme: Theme.of(context).textTheme.apply(
      bodyColor: Colors.white.withOpacity(0.6),
      displayColor: Colors.white.withOpacity(0.6),
    ),
    cardTheme: const CardTheme(
      color: Color(0XFF191919),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Color(0Xff121212),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0XFF191919),
      contentTextStyle: TextStyle(color: Colors.white.withOpacity(0.6),)
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:  const Color(0Xff121212),
      selectedItemColor: myColor,
      unselectedItemColor: Colors.grey.withOpacity(0.3),
      selectedIconTheme: const IconThemeData(color: myColor),
      showUnselectedLabels: true,
    ),
  );
}
