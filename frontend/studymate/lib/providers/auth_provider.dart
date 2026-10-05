import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api.dart';

// holds the logged in user and the session token
class AuthProvider extends ChangeNotifier {
  String? userId;
  String? name;
  String? email;
  String? token;
  bool loading = false;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  // called once on app start to bring back the saved session
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    name = prefs.getString("name");
    email = prefs.getString("email");
    notifyListeners();
  }

  Future<String?> login(String email, String password) {
    return _authCall("/api/auth/login", {
      "email": email.trim(),
      "password": password,
    });
  }

  Future<String?> register(String name, String email, String password) {
    return _authCall("/api/auth/register", {
      "name": name.trim(),
      "email": email.trim(),
      "password": password,
    });
  }

  // returns null on success, otherwise the error message to show
  Future<String?> _authCall(String path, Map<String, dynamic> body) async {
    loading = true;
    notifyListeners();
    try {
      final data = await Api().post(path, body);
      userId = data["userId"] as String?;
      name = data["name"] as String?;
      email = data["email"] as String?;
      token = data["token"] as String?;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token!);
      await prefs.setString("name", name ?? "");
      await prefs.setString("email", email ?? "");
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final oldToken = token;
    token = null;
    userId = null;
    name = null;
    email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("name");
    await prefs.remove("email");
    notifyListeners();

    // tell the server to drop the token, but don't wait for it
    if (oldToken != null) {
      try {
        await Api(token: oldToken).post("/api/auth/logout", {});
      } catch (_) {}
    }
  }
}
