import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DashboardService {

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }

  // ✅ FIXED: single correct endpoint
  static Future<Map<String, dynamic>> getMetrics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to load dashboard');
      }

      final data = jsonDecode(res.body);

      return {
        "users": data["users"] ?? 0,
        "posts": data["posts"] ?? 0,
        "comments": data["comments"] ?? 0,
      };
    } catch (e) {
      return {
        "users": 0,
        "posts": 0,
        "comments": 0,
      };
    }
  }

  // ⚠️ These two still don't exist in backend (safe fallback)
  static Future<Map<String, dynamic>> getSentiment() async {
    return {"positive": 0, "neutral": 0, "negative": 0};
  }

  static Future<Map<String, dynamic>> getReportsStats() async {
    return {};
  }
}