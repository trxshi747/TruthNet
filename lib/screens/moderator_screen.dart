import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'package:model2/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

import 'moderator/reports_screen.dart';
import 'moderator/moderator_users_screen.dart';

class ModeratorScreen extends StatefulWidget {
  const ModeratorScreen({super.key});

  @override
  State<ModeratorScreen> createState() => _ModeratorScreenState();
}

class _ModeratorScreenState extends State<ModeratorScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    "Reports",
    "Users & Sanctions",
  ];

  late final List<Widget> pages = [
    const ReportsScreen(),
    const ModeratorUsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Row(
        children: [
          // ================= SIDEBAR =================
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: AppTheme.darkPurple.withOpacity(0.9),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Text(
                  "MODERATOR PANEL",
                  style: GoogleFonts.righteous(
                    color: AppTheme.peach,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView.builder(
                    itemCount: titles.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;

                      return InkWell(
                        onTap: () {
                          setState(() => selectedIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.peach.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getIcon(index),
                                color: isSelected
                                    ? AppTheme.peach
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                titles[index],
                                style: GoogleFonts.spaceMono(
                                  color: isSelected
                                      ? AppTheme.peach
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: InkWell(
                    onTap: () {
                      auth.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.coral),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: AppTheme.coral),
                          const SizedBox(width: 10),
                          Text(
                            "LOGOUT",
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.coral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: DynamicBackground(
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.report;
      case 1:
        return Icons.gavel;
      default:
        return Icons.circle;
    }
  }
}
