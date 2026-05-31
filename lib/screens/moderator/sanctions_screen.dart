import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

class SanctionsScreen extends StatefulWidget {
  const SanctionsScreen({super.key});

  @override
  State<SanctionsScreen> createState() => _SanctionsScreenState();
}

class _SanctionsScreenState extends State<SanctionsScreen> {
  List users = [];

  @override
  void initState() {
    super.initState();
    users = [
      {"name": "Alice", "status": "SUSPENDED"},
      {"name": "Bob", "status": "BANNED"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Sanctions")),
      body: DynamicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];

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
                  Text(u['name'],
                      style: GoogleFonts.righteous(color: Colors.white)),
                  Text(u['status'],
                      style: GoogleFonts.spaceMono(color: Colors.orange)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text("Lift"),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Ban",
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