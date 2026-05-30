import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_moderator_screen.dart';
import 'admin/admin_role_screen.dart';
import 'admin/admin_users_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    "Dashboard",
    "Users",
    "Moderators",
    "Roles",
    "Rules",
    "Settings",
  ];

  late final List<Widget> pages = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminModeratorsScreen(),
    const AdminRoleScreen(),
    const Center(child: Text("RULES")),
    const Center(child: Text("SETTINGS")),
  ];

  @override
  Widget build(BuildContext context) {
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
                  "ADMIN PANEL",
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
        return Icons.analytics;
      case 1:
        return Icons.people;
      case 2:
        return Icons.admin_panel_settings;
      case 3:
        return Icons.assignment_ind;
      case 4:
        return Icons.gavel;
      case 5:
        return Icons.settings;
      default:
        return Icons.circle;
    }
  }
}