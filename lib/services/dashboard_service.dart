import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DashboardService {

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }

  // KPI global
  static Future<Map<String, dynamic>> getMetrics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/metrics'),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {};
    }
  }

  // sentiment analysis
  static Future<Map<String, dynamic>> getSentiment() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/sentiment'),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {"positive": 0, "neutral": 0, "negative": 0};
    }
  }

  // reports stats
  static Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/reports'),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {};
    }
  }



}