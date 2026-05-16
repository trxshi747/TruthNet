import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_moderator_screen.dart';
import 'admin/admin_role_screen.dart';
import 'admin/admin_users_screen.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ADMIN_CONTROL_CENTER', style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.all(20),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildAdminUsersCard(context, 'USER_MANAGEMENT', Icons.people, AppTheme.peach),
              _buildAdminModCard(context, 'MODERATOR_TEAM', Icons.admin_panel_settings, AppTheme.coral),
              _buildAdminCard(context, 'PLATFORM_RULES', Icons.gavel, AppTheme.peach),
              _buildAdminCard(context, 'SYSTEM_SETTINGS', Icons.settings, AppTheme.coral),
              _buildAdminRolesCard(context, 'ROLE_DEFINITIONS', Icons.assignment_ind, AppTheme.peach),
              _buildAdminDashboardCard(context, 'SYSTEM_DASHBOARD', Icons.analytics, AppTheme.coral),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: AppTheme.mediumPurple.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminRolesCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: AppTheme.mediumPurple.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRoleScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAdminDashboardCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: AppTheme.mediumPurple.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminUsersCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: AppTheme.mediumPurple.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminModCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: AppTheme.mediumPurple.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminModeratorsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
