import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

// One small helper class used for every call to the backend.
// Every endpoint is a POST that returns json.
class Api {
  final String? token;

  Api({this.token});

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    if (backendUrl.contains("your-deployment")) {
      throw ApiException("Backend url not set - edit lib/utils/config.dart");
    }

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse("$backendUrl$path"),
            headers: {
              "Content-Type": "application/json",
              if (token != null && token!.isNotEmpty) "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException("Cannot reach the server. Is `npx convex dev` running?");
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException("Server sent a bad response");
    }

    if (res.statusCode >= 400) {
      throw ApiException((data["error"] ?? "Something went wrong").toString());
    }
    return data;
  }
}
