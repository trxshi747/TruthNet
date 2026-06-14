import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/core/theme/app_theme.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _openUserForm({Map<String, dynamic>? user}) {
    final firstNameController = TextEditingController(text: user?['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user?['lastName'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user == null ? "ADD_USER" : "EDIT_USER",
                style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 20),
              ),
              const SizedBox(height: 20),
              _buildInput("FIRST NAME", firstNameController),
              _buildInput("LAST NAME", lastNameController),
              _buildInput("EMAIL", emailController),
              _buildInput("USERNAME", usernameController),
              if (user == null)
                _buildInput("PASSWORD", passwordController, obscure: true),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.peach,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (emailController.text.isEmpty || usernameController.text.isEmpty) return;

                  final data = {
                    "firstName": firstNameController.text,
                    "lastName": lastNameController.text,
                    "email": emailController.text,
                    "username": usernameController.text,
                  };

                  if (user == null) {
                    data["password"] = passwordController.text;
                    // Note: register endpoint is used for adding users
                    final res = await ApiService.register(
                      data['email']!,
                      data['password']!,
                      data['firstName']!,
                      data['lastName']!,
                      data['username']!,
                      'Member'
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      if (res['success'] == true) {
                        fetchUsers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? "OPERATION_FAILED")),
                        );
                      }
                    }
                  } else {
                    // Update user (We use updateModerator logic for users too if compatible or add specific endpoint)
                    // For now let's use updateModerator since it's just updating User node properties
                    final res = await ApiService.updateModerator(user['id'], data);
                    if (mounted) {
                      Navigator.pop(context);
                      if (res['success'] == true) {
                        fetchUsers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? "OPERATION_FAILED")),
                        );
                      }
                    }
                  }
                },
                child: Text("SAVE", style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.spaceMono(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
    );
  }

  void _deleteUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text("DELETE_USER", style: GoogleFonts.righteous(color: Colors.redAccent)),
        content: Text("THIS_ACTION_CANNOT_BE_UNDONE", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("DELETE", style: GoogleFonts.spaceMono(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ApiService.deleteUser(id);
    if (success) {
      fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DELETE_FAILED")));
    }
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim().isEmpty 
                      ? user['username'] ?? 'UNKNOWN' 
                      : "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}",
                  style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Text(
                  user['status'] ?? 'ACTIVE',
                  style: GoogleFonts.spaceMono(color: Colors.green, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("@${user['username'] ?? 'unknown'}", style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 11)),
          const SizedBox(height: 5),
          Text(user['email'] ?? "N/A", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () => _openUserForm(user: user)),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () => _deleteUser(user['id'])),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("User Management", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: fetchUsers)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.peach,
        onPressed: () => _openUserForm(),
        child: const Icon(Icons.add, color: AppTheme.darkPurple),
      ),
      body: DynamicBackground(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
          : _users.isEmpty
            ? const Center(child: Text("NO_USERS_FOUND", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _users.length,
                itemBuilder: (_, i) => _buildUserCard(_users[i]),
              ),
      ),
    );
  }
}
