import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/dashboard_service.dart';

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
      appBar: AppBar(title: const Text("Admin Dashboard")),
      /*
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // KPI GRID
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              children: [
                kpiCard("Users", "${metrics["users"] ?? 0}", Icons.person),
                kpiCard("Posts", "${metrics["posts"] ?? 0}", Icons.post_add),
                kpiCard("Comments", "${metrics["comments"] ?? 0}", Icons.comment),
                kpiCard("Reports", "${metrics["reports"] ?? 0}", Icons.report),
              ],
            ),

            const SizedBox(height: 20),

            Text("Sentiment Analysis",
                style: GoogleFonts.righteous(color: Colors.white)),

            const SizedBox(height: 10),

            SizedBox(height: 200, child: sentimentChart()),
          ],
        ),
      ),
      */
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // évite double scroll
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                children: [
                  kpiCard("Users", "${metrics["users"] ?? 0}", Icons.person),
                  kpiCard("Posts", "${metrics["posts"] ?? 0}", Icons.post_add),
                  kpiCard("Comments", "${metrics["comments"] ?? 0}", Icons.comment),
                  kpiCard("Reports", "${metrics["reports"] ?? 0}", Icons.report),
                ],
              ),
              const SizedBox(height: 20),
              Text("Sentiment Analysis",
                  style: GoogleFonts.righteous(color: Colors.white)),
              const SizedBox(height: 10),
              SizedBox(height: 200, child: sentimentChart()),
            ],
          ),
        ),
      ),

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF48426D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF0C38E)),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.righteous(color: Colors.white, fontSize: 18)),
          Text(title,
              style: GoogleFonts.spaceMono(
                  color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget sentimentChart() {
    final positive = (sentiment["positive"] ?? 0).toDouble();
    final neutral = (sentiment["neutral"] ?? 0).toDouble();
    final negative = (sentiment["negative"] ?? 0).toDouble();

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: positive, color: Colors.green),
          PieChartSectionData(value: neutral, color: Colors.orange),
          PieChartSectionData(value: negative, color: Colors.red),
        ],
      ),
    );
  }



}