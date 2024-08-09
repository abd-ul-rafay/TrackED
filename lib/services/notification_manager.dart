import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static const String _sendNotificationKey = 'SEND_NOTIFICATION';
  static const String _customMessageKey = 'CUSTOM_MESSAGE';

  static Future<void> saveSendNotification(int toggleLabelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    bool sendNotification = toggleLabelIndex != 0;
    await prefs.setBool(_sendNotificationKey, sendNotification);
  }

  static Future<bool> getSendNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sendNotificationKey) ?? false;
  }

  static Future<void> saveCustomMessage(String inText, String outText) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> customMessageText = {
      'inText': inText,
      'outText': outText
    };
    String customMessageJson = jsonEncode(customMessageText);
    await prefs.setString(_customMessageKey, customMessageJson);
  }

  static Future<Map<String, String>?> getCustomMessage() async {
    final prefs = await SharedPreferences.getInstance();
    String? customMessageJson = prefs.getString(_customMessageKey);
    if (customMessageJson == null) {
      return null;
    }
    Map<String, dynamic> customMessageMap = jsonDecode(customMessageJson);
    return customMessageMap.map((key, value) => MapEntry(key, value.toString()));
  }

  // Clear custom message map
  static Future<void> clearCustomMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customMessageKey);
  }
}
