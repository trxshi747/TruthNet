import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class SentimentStats {
  final int positive;
  final int neutral;
  final int negative;
  final int total;
  final Map<String, double> avgScores;
  final Map<String, int> negativityBreakdown;

  const SentimentStats({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.total,
    required this.avgScores,
    required this.negativityBreakdown,
  });

  factory SentimentStats.fromJson(Map<String, dynamic> json) {
    final avg = json['avg_scores'] as Map<String, dynamic>? ?? {};
    final neg = json['negativity_breakdown'] as Map<String, dynamic>? ?? {};
    return SentimentStats(
      positive: _i(json['positive']),
      neutral: _i(json['neutral']),
      negative: _i(json['negative']),
      total: _i(json['total']),
      avgScores: {
        'positive': _d(avg['positive']),
        'neutral': _d(avg['neutral']),
        'negative': _d(avg['negative']),
      },
      negativityBreakdown: {
        'low': _i(neg['low']),
        'moderate': _i(neg['moderate']),
        'high': _i(neg['high']),
        'extreme': _i(neg['extreme']),
      },
    );
  }

  static const empty = SentimentStats(
    positive: 0,
    neutral: 0,
    negative: 0,
    total: 0,
    avgScores: {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0},
    negativityBreakdown: {'low': 0, 'moderate': 0, 'high': 0, 'extreme': 0},
  );

  double get positiveRate => total == 0 ? 0 : positive / total;
  double get negativeRate => total == 0 ? 0 : negative / total;
  double get neutralRate => total == 0 ? 0 : neutral / total;
}

class ToxicityStats {
  final int total;
  final int toxicCount;
  final int cleanCount;
  final double toxicRate;
  final double avgToxicScore;
  final Map<String, int> degreeBreakdown;
  final int severeFlagCount;
  final Map<String, int> categoryCounts;

  const ToxicityStats({
    required this.total,
    required this.toxicCount,
    required this.cleanCount,
    required this.toxicRate,
    required this.avgToxicScore,
    required this.degreeBreakdown,
    required this.severeFlagCount,
    required this.categoryCounts,
  });

  factory ToxicityStats.fromJson(Map<String, dynamic> json) {
    final deg = json['degree_breakdown'] as Map<String, dynamic>? ?? {};
    final cat = json['category_counts'] as Map<String, dynamic>? ?? {};
    return ToxicityStats(
      total: _i(json['total']),
      toxicCount: _i(json['toxic_count']),
      cleanCount: _i(json['clean_count']),
      toxicRate: _d(json['toxic_rate']),
      avgToxicScore: _d(json['avg_toxic_score']),
      degreeBreakdown: {
        'low': _i(deg['low']),
        'moderate': _i(deg['moderate']),
        'high': _i(deg['high']),
        'extreme': _i(deg['extreme']),
      },
      severeFlagCount: _i(json['severe_flag_count']),
      categoryCounts: cat.map((k, v) => MapEntry(k, _i(v))),
    );
  }

  static const empty = ToxicityStats(
    total: 0,
    toxicCount: 0,
    cleanCount: 0,
    toxicRate: 0.0,
    avgToxicScore: 0.0,
    degreeBreakdown: {'low': 0, 'moderate': 0, 'high': 0, 'extreme': 0},
    severeFlagCount: 0,
    categoryCounts: {},
  );
}

class TruthnessTrendPoint {
  final String day;
  final double averageScore;
  final int count;

  const TruthnessTrendPoint({
    required this.day,
    required this.averageScore,
    required this.count,
  });

  factory TruthnessTrendPoint.fromJson(Map<String, dynamic> json) {
    return TruthnessTrendPoint(
      day: json['day']?.toString() ?? '',
      averageScore: _d(json['averageScore']),
      count: _i(json['count']),
    );
  }
}

class TruthnessSummary {
  final int total;
  final double averageScore;
  final Map<String, int> distribution;
  final List<TruthnessTrendPoint> trend;

  const TruthnessSummary({
    required this.total,
    required this.averageScore,
    required this.distribution,
    required this.trend,
  });

  factory TruthnessSummary.fromJson(Map<String, dynamic> json) {
    final distribution = json['distribution'] as Map<String, dynamic>? ?? {};
    final trend = (json['trend'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              TruthnessTrendPoint.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return TruthnessSummary(
      total: _i(json['total']),
      averageScore: _d(json['averageScore']),
      distribution: {
        'reliable': _i(distribution['reliable']),
        'uncertain': _i(distribution['uncertain']),
        'lowTrust': _i(distribution['lowTrust']),
      },
      trend: trend,
    );
  }

  static const empty = TruthnessSummary(
    total: 0,
    averageScore: 0.0,
    distribution: {'reliable': 0, 'uncertain': 0, 'lowTrust': 0},
    trend: [],
  );
}

class DashboardSummary {
  final int totalComments;
  final SentimentStats sentiment;
  final ToxicityStats toxicity;
  final List<Map<String, dynamic>> topToxicCategories;

  const DashboardSummary({
    required this.totalComments,
    required this.sentiment,
    required this.toxicity,
    required this.topToxicCategories,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final cats = (json['top_toxic_categories'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return DashboardSummary(
      totalComments: _i(json['total']),
      sentiment: SentimentStats.fromJson(
        json['sentiment'] as Map<String, dynamic>? ?? {},
      ),
      toxicity: ToxicityStats.fromJson(
        json['toxicity'] as Map<String, dynamic>? ?? {},
      ),
      topToxicCategories: cats,
    );
  }

  static const empty = DashboardSummary(
    totalComments: 0,
    sentiment: SentimentStats.empty,
    toxicity: ToxicityStats.empty,
    topToxicCategories: [],
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

// ─── Service ──────────────────────────────────────────────────────────────────

class DashboardService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }

  // ── Platform counts (users, posts, comments, reports) ──────────────────────────────
  static Future<Map<String, dynamic>> getMetrics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/dashboard'));
      if (res.statusCode != 200) throw Exception('Failed to load dashboard');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'users': data['users'] ?? 0,
        'posts': data['posts'] ?? 0,
        'comments': data['comments'] ?? 0,
        'reports': data['reports'] ?? 0,
        'pendingReports': data['pendingReports'] ?? 0,
        'resolvedReports': data['resolvedReports'] ?? 0,
      };
    } catch (_) {
      return {
        'users': 0,
        'posts': 0,
        'comments': 0,
        'reports': 0,
        'pendingReports': 0,
        'resolvedReports': 0,
      };
    }
  }

  // ── AI Dashboard summary (sentiment + toxicity) ────────────────────────────
  static Future<DashboardSummary> getDashboardAISummary({
    int limit = 200,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/ai/dashboard-sentiment?limit=$limit'),
      );
      if (res.statusCode != 200) return DashboardSummary.empty;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] != true) return DashboardSummary.empty;
      return DashboardSummary.fromJson(json);
    } catch (e) {
      debugPrint('getDashboardAISummary error: $e');
      return DashboardSummary.empty;
    }
  }

  // ── Kept for backward compatibility ───────────────────────────────────────
  static Future<TruthnessSummary> getTruthnessSummary() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/truthness-summary'));
      if (res.statusCode != 200) return TruthnessSummary.empty;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] != true) return TruthnessSummary.empty;
      return TruthnessSummary.fromJson(json);
    } catch (e) {
      debugPrint('getTruthnessSummary error: $e');
      return TruthnessSummary.empty;
    }
  }

  static Future<Map<String, dynamic>> getSentiment() async {
    try {
      final summary = await getDashboardAISummary(limit: 200);
      return {
        'positive': summary.sentiment.positive,
        'neutral': summary.sentiment.neutral,
        'negative': summary.sentiment.negative,
        'total': summary.sentiment.total,
      };
    } catch (_) {
      return {'positive': 0, 'neutral': 0, 'negative': 0, 'total': 0};
    }
  }

  // ── AI health check ────────────────────────────────────────────────────────
  static Future<bool> isAIServiceAvailable() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ai/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['ai_service'] != 'unreachable';
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getReportsStats() async => {};
}
