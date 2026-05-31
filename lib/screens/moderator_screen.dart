import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'moderator/reports_screen.dart';
import 'moderator/sanctions_screen.dart';

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
              _header(),

              const SizedBox(height: 20),

              _kpis(),

              const SizedBox(height: 25),

              _sectionTitle("Quick Actions"),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      context,
                      "Reports",
                      Icons.report,
                      Colors.orange,
                      const ReportsScreen(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionCard(
                      context,
                      "Sanctions",
                      Icons.gavel,
                      Colors.blue,
                      const SanctionsScreen(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              _sectionTitle("Recent Activity"),

              const SizedBox(height: 12),

              _activity("Post #1234 removed", "Hate speech - 10 min ago"),
              _activity("User suspended", "Spam detected - 1h ago"),
              _activity("Report resolved", "False positive - 2h ago"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Moderation Dashboard",
          style: GoogleFonts.righteous(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 6),
        Text(
          "Monitor reports and user safety",
          style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _kpis() {
    return Row(
      children: [
        Expanded(child: _kpi("Reports", "15", Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _kpi("Suspended", "3", Colors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _kpi("Banned", "2", Colors.red)),
      ],
    );
  }

  Widget _kpi(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.mediumPurple.withOpacity(0.3),
            AppTheme.peach.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(Icons.circle, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.righteous(color: Colors.white, fontSize: 18)),
          Text(title,
              style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _actionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      Widget page,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
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
            Text(title,
                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.righteous(color: Colors.white, fontSize: 16),
    );
  }

  Widget _activity(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
                Text(subtitle,
                    style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}