import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:model2/core/theme/app_theme.dart';

import '../../services/dashboard_service.dart';
import '../../widgets/dynamic_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> metrics = {};
  Map<String, dynamic> sentiment = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Admin Dashboard")),

        body: DynamicBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


            // ───────── HEADER SECTION ─────────
            Text(
              "Overview",
              style: GoogleFonts.righteous(
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Platform analytics & system health",
              style: GoogleFonts.spaceMono(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 25),

            // ───────── KPI SECTION ─────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                //color: const Color(0xFF1A1A2E),
                color: AppTheme.peach.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  kpiCard("Users", "${metrics["users"] ?? 0}", Icons.person),
                  kpiCard("Posts", "${metrics["posts"] ?? 0}", Icons.post_add),
                  kpiCard("Comments", "${metrics["comments"] ?? 0}", Icons.comment),
                  kpiCard("Reports", "${metrics["reports"] ?? 0}", Icons.report),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ───────── ANALYTICS HEADER ─────────
            Text(
              "AI Sentiment Analytics",
              style: GoogleFonts.righteous(
                fontSize: 18,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // ───────── CHART CONTAINER ─────────
            Container(
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                //color: const Color(0xFF1A1A2E),
                color: AppTheme.peach.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: sentimentChart(),
            ),
          ],
        ),
      ),
    )
    );
  }

  Future<void> loadDashboard() async {
    final m = await DashboardService.getMetrics();
    final s = await DashboardService.getSentiment();

    setState(() {
      metrics = m;
      sentiment = s;
      loading = false;
    });
  }

  Widget kpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.mediumPurple.withOpacity(0.35),
            AppTheme.peach.withOpacity(0.15), // 👈 replace black
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            //color: Colors.black.withOpacity(0.3),
            color: AppTheme.peach.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.peach, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget legend(String label, Color color, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 8),
          Text(
            "$label: ${value.toInt()}",
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget sentimentChart() {
    final positive = (sentiment["positive"] ?? 0).toDouble();
    final neutral = (sentiment["neutral"] ?? 0).toDouble();
    final negative = (sentiment["negative"] ?? 0).toDouble();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: positive,
                  color: Colors.green,
                  radius: 50,
                  title: "😊",
                ),
                PieChartSectionData(
                  value: neutral,
                  color: Colors.orange,
                  radius: 50,
                  title: "😐",
                ),
                PieChartSectionData(
                  value: negative,
                  color: Colors.red,
                  radius: 50,
                  title: "😡",
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            legend("Positive", Colors.green, positive),
            legend("Neutral", Colors.orange, neutral),
            legend("Negative", Colors.red, negative),
          ],
        )
      ],
    );
  }


}