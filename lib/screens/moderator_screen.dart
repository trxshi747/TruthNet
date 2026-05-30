import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

class ModeratorScreen extends StatelessWidget {
  const ModeratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Moderation Panel"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DynamicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildKpiRow(),

              const SizedBox(height: 25),

              _buildQuickActions(),

              const SizedBox(height: 25),

              _buildSectionTitle("Recent Activity"),

              const SizedBox(height: 10),

              _buildActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Moderation Dashboard",
          style: GoogleFonts.righteous(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Monitor reports, bans, and user safety",
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  // ───────────────── KPI CARDS ─────────────────

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(child: _kpiCard("Reports", "15", Icons.report, Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _kpiCard("Suspended", "3", Icons.pause, Colors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _kpiCard("Banned", "2", Icons.block, Colors.red)),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.mediumPurple.withOpacity(0.3),
            AppTheme.peach.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── QUICK ACTIONS ─────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Quick Actions"),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _actionCard("Reports", Icons.report, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _actionCard("Suspensions", Icons.pause, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _actionCard("Bans", Icons.block, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkPurple.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── SECTION TITLE ─────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.righteous(
        fontSize: 16,
        color: Colors.white,
      ),
    );
  }

  // ───────────────── ACTIVITY LIST ─────────────────

  Widget _buildActivityList() {
    return Column(
      children: [
        _activityItem("Post #1234 removed", "Hate speech - 10 min ago"),
        _activityItem("User suspended", "Spam detection - 1h ago"),
        _activityItem("Report resolved", "False positive - 2h ago"),
      ],
    );
  }

  Widget _activityItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}