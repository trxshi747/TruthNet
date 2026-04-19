import 'package:flutter/material.dart';

class ModeratorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moderation Panel')),
      body: ListView(
        children: [
          _buildModTile(
            context,
            'Pending Reports',
            '15 new reports to review',
            Icons.report_problem,
            Colors.orange,
          ),
          _buildModTile(
            context,
            'Manage Suspensions',
            'View and lift user suspensions',
            Icons.pause_circle_filled,
            Colors.blue,
          ),
          _buildModTile(
            context,
            'Ban List',
            'Permanent bans management',
            Icons.block,
            Colors.red,
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Placeholder for recent moderation actions
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Post #1234 removed'),
            subtitle: Text('Reason: Hate speech - 10 mins ago'),
          ),
        ],
      ),
    );
  }

  Widget _buildModTile(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
