import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List reports = [];

  @override
  void initState() {
    super.initState();
    reports = [
      {"id": 1, "postId": 101, "reason": "Hate speech"},
      {"id": 2, "postId": 102, "reason": "Spam"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Reports")),
      body: DynamicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.mediumPurple.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Post #${r['postId']}",
                      style: GoogleFonts.righteous(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text("Reason: ${r['reason']}",
                      style: GoogleFonts.spaceMono(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text("Resolve"),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}