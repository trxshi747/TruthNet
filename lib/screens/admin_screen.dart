import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildAdminCard(context, 'User Management', Icons.people, Colors.blue),
          _buildAdminCard(context, 'Moderator Team', Icons.admin_panel_settings, Colors.indigo),
          _buildAdminCard(context, 'Platform Rules', Icons.gavel, Colors.brown),
          _buildAdminCard(context, 'System Settings', Icons.settings, Colors.grey),
          _buildAdminCard(context, 'Role Definitions', Icons.assignment_ind, Colors.purple),
          _buildAdminCard(context, 'System Analytics', Icons.analytics, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
