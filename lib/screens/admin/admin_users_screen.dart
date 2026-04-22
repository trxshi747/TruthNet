import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getAllUsers();
      // si backend vide → fallback mock
      if (users.isEmpty) {
        _users = _mockUsers();
      } else {
        _users = users;
      }
    } catch (e) {
      // si erreur → mock direct
      _users = _mockUsers();
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _mockUsers() {
    return [
      {
        "id": "1",
        "name": "Alice Johnson",
        "email": "alice@mail.com",
        "role": "user",
      },
      {
        "id": "2",
        "name": "Test User",
        "email": "test@mail.com",
        "role": "user",
      },
      {
        "id": "3",
        "name": "Lilly Bolossom",
        "email": "lilly@mail.com",
        "role": "user",
      },
    ];
  }

  Future<void> _confirmAction(String title, Function action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF312C51),
        title: Text(title, style: GoogleFonts.righteous(color: Colors.redAccent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("CONFIRM", style: GoogleFonts.spaceMono(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
      fetchUsers();
    }
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF48426D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER INFO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user['name'] ?? "UNKNOWN",
                style: GoogleFonts.righteous(
                  color: const Color(0xFFF0C38E),
                  fontSize: 16,
                ),
              ),
              Text(
                user['role'] ?? "user",
                style: GoogleFonts.spaceMono(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            user['email'] ?? "",
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11),
          ),

          const SizedBox(height: 10),

          // ACTIONS
          Wrap(
            spacing: 8,
            children: [
              _actionButton("BAN", Colors.redAccent, () {
                _confirmAction("BAN USER ?", () => ApiService.banUser(user['id']));
              }),
              _actionButton("DEACTIVATE", Colors.orange, () {
                _confirmAction("DEACTIVATE USER ?", () => ApiService.deactivateUser(user['id']));
              }),
              _actionButton("DELETE", Colors.red, () {
                _confirmAction("DELETE USER ?", () => ApiService.deleteUser(user['id']));
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(color: color, fontSize: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: DynamicBackground(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF0C38E)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("User Management")),
      body: DynamicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(_users[index]);
          },
        ),
      ),
    );
  }
}