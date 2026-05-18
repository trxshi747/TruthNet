import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'SYSTEM_SETTINGS',
            style: GoogleFonts.righteous(fontSize: 20, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}