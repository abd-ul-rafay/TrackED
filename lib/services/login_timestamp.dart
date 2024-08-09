import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LoginTimestamp {
  static const String _loginTimestampKey = 'LOGIN_TIMESTAMP';

  Future<void> saveLoginTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isLoginExpired(double periodInDays) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimestampKey) ?? 0;
    final periodInMilliseconds = periodInDays * 24 * 60 * 60 * 1000;

    if (loginTime == 0) {
      return false;
    }

    // print('Current Time: $currentTime');
    // print('Login Time: $loginTime');
    // print('Current Time - Login Time: ${currentTime - loginTime}');
    // print('Period In Milliseconds: $periodInMilliseconds');
    // print('Diff b/w Current Time and Login Time greater than Period? ${(currentTime - loginTime) > periodInMilliseconds}');
    return (currentTime - loginTime) > periodInMilliseconds;
  }
}
