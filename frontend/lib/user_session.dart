import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// A simple data class for the user
class AppUser {
  final String id;
  final String nickname;

  AppUser({required this.id, required this.nickname});

  // Factory constructor to create a User from a map
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      nickname: json['nickname'],
    );
  }

  // Method to convert a User to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
    };
  }
}

class UserSession {
  static const String _userKey = 'user';

  // Save user data to SharedPreferences
  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  // Get user data from SharedPreferences
  static Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return AppUser.fromJson(json.decode(userJson));
    }
    return null;
  }

  // Clear user data from SharedPreferences (for logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
