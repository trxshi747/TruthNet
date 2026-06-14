import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/dashboard_service.dart';
import '../../widgets/dynamic_background.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _metrics   = {};
  DashboardSummary     _aiSummary = DashboardSummary.empty;
  bool _loading    = true;
  bool _aiOnline   = false;
  bool _aiLoading  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _aiLoading = true; });

    // Load platform metrics and AI status in parallel
    final results = await Future.wait([
      DashboardService.getMetrics(),
      DashboardService.isAIServiceAvailable(),
      DashboardService.getDashboardAISummary(limit: 200),
    ]);

    if (mounted) {
      setState(() {
        _metrics   = results[0] as Map<String, dynamic>;
        _aiOnline  = results[1] as bool;
        _aiSummary = results[2] as DashboardSummary;
        _loading   = false;
        _aiLoading = false;
      });
    }
  }

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF0E1117);
  static const _card    = Color(0xFF161B25);
  static const _border  = Color(0xFF252D3D);
  static const _textPri = Color(0xFFF0F2F5);
  static const _textSec = Color(0xFF7B8499);
  static const _green   = Color(0xFF2ECC71);
  static const _red     = Color(0xFFEE2727);
  static const _amber   = Color(0xFFFFCF26);
  static const _blue    = Color(0xFF4D9FEC);
  static const _cyan    = Color(0xFF26E5FF);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.righteous(color: _textPri),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // AI status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _aiOnline ? _green : _red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _aiOnline ? 'AI online' : 'AI offline',
                  style: TextStyle(
                    fontSize: 11, color: _aiOnline ? _green : _red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSec),
            onPressed: _load,
          ),
        ],
      ),
      body: DynamicBackground(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Section header ─────────────────────────────────────
                _sectionTitle('Overview'),
                _sectionSubtitle('Platform analytics & system health'),
                const SizedBox(height: 20),

                // ── KPI grid ────────────────────────────────────────────
                _KpiGrid(metrics: _metrics),
                const SizedBox(height: 28),

                // ── AI Sentiment ────────────────────────────────────────
                Row(
                  children: [
                    _sectionTitle('Sentiment Analysis'),
                    const Spacer(),
                    if (_aiLoading)
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            color: _blue, strokeWidth: 1.5),
                      )
                    else if (!_aiOnline)
                      const _AIOfflineBadge(),
                  ],
                ),
                _sectionSubtitle(
                    'Analysed ${_aiSummary.totalComments} recent comments'),
                const SizedBox(height: 14),

                _SentimentCard(
                  stats:    _aiSummary.sentiment,
                  loading:  _aiLoading,
                  offline:  !_aiOnline,
                ),
                const SizedBox(height: 16),

                // ── Negativity breakdown ────────────────────────────────
                _BreakdownCard(
                  title:      'Negativity Breakdown',
                  subtitle:   'Distribution of negative comment intensity',
                  breakdown:  _aiSummary.sentiment.negativityBreakdown,
                  colors: {
                    'low':      _blue,
                    'moderate': _amber,
                    'high':     const Color(0xFFE87F3A),
                    'extreme':  _red,
                  },
                  loading: _aiLoading,
                ),
                const SizedBox(height: 28),

                // ── Toxicity ────────────────────────────────────────────
                _sectionTitle('Toxicity Analysis'),
                _sectionSubtitle(
                    '${(_aiSummary.toxicity.toxicRate * 100).toStringAsFixed(1)}% '
                        'of comments flagged as toxic'),
                const SizedBox(height: 14),

                _ToxicityCard(
                  stats:   _aiSummary.toxicity,
                  loading: _aiLoading,
                  offline: !_aiOnline,
                ),
                const SizedBox(height: 16),

                // ── Toxicity degree breakdown ────────────────────────────
                _BreakdownCard(
                  title:     'Toxicity Degree Breakdown',
                  subtitle:  'Severity distribution across flagged content',
                  breakdown: _aiSummary.toxicity.degreeBreakdown,
                  colors: {
                    'low':      _green,
                    'moderate': _amber,
                    'high':     const Color(0xFFE87F3A),
                    'extreme':  _red,
                  },
                  loading: _aiLoading,
                ),
                const SizedBox(height: 16),

                // ── Top toxic categories ──────────────────────────────────
                if (_aiSummary.topToxicCategories.isNotEmpty)
                  _TopCategoriesCard(
                    categories: _aiSummary.topToxicCategories,
                    loading:    _aiLoading,
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.righteous(fontSize: 20, color: _textPri),
  );

  Widget _sectionSubtitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text(text,
        style: GoogleFonts.spaceMono(fontSize: 11, color: _textSec)),
  );
}

// ─── KPI Grid ────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _KpiGrid({required this.metrics});

  static const _bg     = Color(0xFF161B25);
  static const _border = Color(0xFF252D3D);

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Users',    '${metrics["users"]    ?? 0}', Icons.person_outline_rounded,    const Color(0xFF4D9FEC)),
      _KpiItem('Posts',    '${metrics["posts"]    ?? 0}', Icons.article_outlined,           const Color(0xFF26E5FF)),
      _KpiItem('Comments', '${metrics["comments"] ?? 0}', Icons.chat_bubble_outline_rounded,const Color(0xFFFFCF26)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: items.map((item) => Expanded(
          child: _KpiCell(item: item, isLast: item == items.last),
        )).toList(),
      ),
    );
  }
}

class _KpiItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiItem(this.label, this.value, this.icon, this.color);
}

class _KpiCell extends StatelessWidget {
  final _KpiItem item;
  final bool isLast;
  const _KpiCell({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(right: BorderSide(color: Color(0xFF252D3D)))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: GoogleFonts.righteous(
                fontSize: 24, color: const Color(0xFFF0F2F5), height: 1),
          ),
          const SizedBox(height: 4),
          Text(item.label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF7B8499))),
        ],
      ),
    );
  }
}

// ─── Sentiment Card ───────────────────────────────────────────────────────────

class _SentimentCard extends StatelessWidget {
  final SentimentStats stats;
  final bool loading;
  final bool offline;

  const _SentimentCard({
    required this.stats,
    required this.loading,
    required this.offline,
  });

  static const _green = Color(0xFF2ECC71);
  static const _amber = Color(0xFFFFCF26);
  static const _red   = Color(0xFFEE2727);
  static const _card  = Color(0xFF161B25);
  static const _border= Color(0xFF252D3D);

  @override
  Widget build(BuildContext context) {
    if (offline) return const _AIOfflineCard();
    if (loading)  return const _LoadingCard(height: 220);

    final total = stats.total == 0 ? 1 : stats.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // ── Pie chart ─────────────────────────────────────────────
          SizedBox(
            width: 160, height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 48,
                    sections: [
                      PieChartSectionData(
                        value: stats.positive.toDouble(),
                        color: _green,
                        radius: 26,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: stats.neutral.toDouble(),
                        color: _amber,
                        radius: 26,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: stats.negative.toDouble(),
                        color: _red,
                        radius: 26,
                        showTitle: false,
                      ),
                      if (stats.total == 0)
                        PieChartSectionData(
                          value: 1,
                          color: _border,
                          radius: 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.total}',
                      style: GoogleFonts.righteous(
                          fontSize: 22,
                          color: const Color(0xFFF0F2F5),
                          height: 1),
                    ),
                    const Text('comments',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF7B8499))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // ── Legend ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SentimentLegend('Positive', stats.positive, total, _green),
                const SizedBox(height: 10),
                _SentimentLegend('Neutral',  stats.neutral,  total, _amber),
                const SizedBox(height: 10),
                _SentimentLegend('Negative', stats.negative, total, _red),
                const SizedBox(height: 14),
                // Avg score display
                Text(
                  'Avg negative score: '
                      '${(stats.avgScores['negative']! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF7B8499)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentLegend extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _SentimentLegend(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFF0F2F5))),
            ]),
            Text('$count  (${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

// ─── Toxicity Card ────────────────────────────────────────────────────────────

class _ToxicityCard extends StatelessWidget {
  final ToxicityStats stats;
  final bool loading;
  final bool offline;

  const _ToxicityCard({
    required this.stats,
    required this.loading,
    required this.offline,
  });

  static const _red   = Color(0xFFEE2727);
  static const _green = Color(0xFF2ECC71);
  static const _card  = Color(0xFF161B25);
  static const _border= Color(0xFF252D3D);

  @override
  Widget build(BuildContext context) {
    if (offline) return const _AIOfflineCard();
    if (loading) return const _LoadingCard(height: 140);

    final toxicPct  = stats.total == 0 ? 0.0 : stats.toxicCount  / stats.total;
    final cleanPct  = stats.total == 0 ? 1.0 : stats.cleanCount  / stats.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: stats.toxicRate > 0.3
              ? _red.withOpacity(0.35)
              : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row ────────────────────────────────────────────
          Row(
            children: [
              _ToxicStat(
                label: 'Toxic',
                value: '${stats.toxicCount}',
                pct:   toxicPct,
                color: _red,
              ),
              const SizedBox(width: 12),
              _ToxicStat(
                label: 'Clean',
                value: '${stats.cleanCount}',
                pct:   cleanPct,
                color: _green,
              ),
              const Spacer(),
              // Toxic rate gauge
              Column(
                children: [
                  Text(
                    '${(stats.toxicRate * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.righteous(
                        fontSize: 26,
                        color: stats.toxicRate > 0.3 ? _red : _green,
                        height: 1),
                  ),
                  const Text('toxic rate',
                      style: TextStyle(fontSize: 10, color: Color(0xFF7B8499))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Progress bar ─────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: toxicPct,
              backgroundColor: _green.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(_red),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 10),

          // ── Avg score + severe count ──────────────────────────────
          Row(
            children: [
              Text(
                'Avg toxic score: '
                    '${(stats.avgToxicScore * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7B8499)),
              ),
              const Spacer(),
              if (stats.severeFlagCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _red.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⚠ ${stats.severeFlagCount} severe flag'
                        '${stats.severeFlagCount > 1 ? "s" : ""}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _red),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToxicStat extends StatelessWidget {
  final String label, value;
  final double pct;
  final Color color;

  const _ToxicStat({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value,
          style: GoogleFonts.righteous(
              fontSize: 20, color: color, height: 1)),
      Text(
        '$label  (${(pct * 100).toStringAsFixed(0)}%)',
        style: const TextStyle(fontSize: 11, color: Color(0xFF7B8499)),
      ),
    ],
  );
}

// ─── Breakdown Card (shared for negativity + toxicity degree) ─────────────────

class _BreakdownCard extends StatelessWidget {
  final String title, subtitle;
  final Map<String, int> breakdown;
  final Map<String, Color> colors;
  final bool loading;

  const _BreakdownCard({
    required this.title,
    required this.subtitle,
    required this.breakdown,
    required this.colors,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingCard(height: 140);

    final total = breakdown.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF252D3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F2F5))),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF7B8499))),
          const SizedBox(height: 14),
          ...['low', 'moderate', 'high', 'extreme'].map((key) {
            final count = breakdown[key] ?? 0;
            final pct   = total == 0 ? 0.0 : count / total;
            final color = colors[key] ?? const Color(0xFF7B8499);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key[0].toUpperCase() + key.substring(1),
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$count  (${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7B8499)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Top Categories Card ─────────────────────────────────────────────────────

class _TopCategoriesCard extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final bool loading;

  const _TopCategoriesCard({required this.categories, required this.loading});

  static const _categoryIcons = {
    'toxic':         Icons.warning_amber_rounded,
    'severe_toxic':  Icons.dangerous_rounded,
    'obscene':       Icons.visibility_off_rounded,
    'threat':        Icons.gavel_rounded,
    'insult':        Icons.sentiment_very_dissatisfied_rounded,
    'identity_hate': Icons.diversity_3_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingCard(height: 120);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF252D3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Toxic Categories',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F2F5))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final label = (cat['category'] as String).replaceAll('_', ' ');
              final count = cat['count'] as int;
              final icon  = _categoryIcons[cat['category']]
                  ?? Icons.flag_rounded;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEE2727).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFEE2727).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13,
                        color: const Color(0xFFEE2727)),
                    const SizedBox(width: 5),
                    Text(
                      '$label · $count',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEE2727)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Utility widgets ──────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF161B25),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF252D3D)),
    ),
    child: const Center(
      child: CircularProgressIndicator(
          color: Color(0xFF4D9FEC), strokeWidth: 2),
    ),
  );
}

class _AIOfflineBadge extends StatelessWidget {
  const _AIOfflineBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEE2727).withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded,
            size: 11, color: Color(0xFFEE2727)),
        SizedBox(width: 4),
        Text('AI offline',
            style: TextStyle(
                fontSize: 10, color: Color(0xFFEE2727))),
      ],
    ),
  );
}

class _AIOfflineCard extends StatelessWidget {
  const _AIOfflineCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF161B25),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
          color: const Color(0xFFEE2727).withOpacity(0.25)),
    ),
    child: const Row(
      children: [
        Icon(Icons.power_off_rounded,
            color: Color(0xFFEE2727), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'AI service is offline. Start the Python server:\n'
                'cd ai_service && python main.py',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF7B8499)),
          ),
        ),
      ],
    ),
  );
}