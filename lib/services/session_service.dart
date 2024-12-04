import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _sessionIdKey = 'session_id';

  //Save session id to shared preferences
  static Future<void> saveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_sessionIdKey, sessionId);

      if (!success) {
        debugPrint('Failed to save Session ID');
        throw Exception('Failed to save Session ID');
      }
    } catch (e) {
      debugPrint('Error in saveSessionId: $e');
      rethrow;
    }
  }

  //Get session id from shared preferences
  static Future<String?> getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString(_sessionIdKey);

      debugPrint('Retrieved session ID: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('Error in getSessionId: $e');
      rethrow;
    }
  }
}
