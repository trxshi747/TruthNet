import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model2/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                user.name[0],
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            Text(
              user.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${user.name.toLowerCase().replaceAll(' ', '_')}',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '12'),
                _buildStatColumn('Followers', '1.2k'),
                _buildStatColumn('Following', '450'),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Edit Profile'),
              ),
            ),
            Divider(height: 40),
            _buildActionList(context, authProvider.role),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionList(BuildContext context, UserRole role) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.bar_chart),
          title: Text('Personal Statistics'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.history),
          title: Text('My Posts'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.comment),
          title: Text('My Comments'),
          onTap: () {},
        ),
        if (role == UserRole.admin) ...[
          Divider(),
          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text('Admin Dashboard'),
            onTap: () {},
          ),
        ],
      ],
    );
  }
}
