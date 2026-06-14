import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';

class AdminRoleScreen extends StatefulWidget {
  const AdminRoleScreen({Key? key}) : super(key: key);

  @override
  State<AdminRoleScreen> createState() => _AdminRoleScreenState();
}

class _AdminRoleScreenState extends State<AdminRoleScreen> {
  List<dynamic> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getRoles();
      if (mounted) {
        setState(() {
          _roles = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roles = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openRoleForm({Map<String, dynamic>? role}) {
    final nameController = TextEditingController(text: role?['name'] ?? '');
    final descController = TextEditingController(text: role?['description'] ?? '');

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              role == null ? "ADD_ROLE" : "EDIT_ROLE",
              style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 20),
            ),
            const SizedBox(height: 20),
            _buildInput("NAME", nameController),
            _buildInput("DESCRIPTION", descController),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.peach,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final data = {
                  "name": nameController.text,
                  "description": descController.text,
                };

                bool success;
                if (role == null) {
                  success = await ApiService.addRole(data);
                } else {
                  success = await ApiService.updateRole(role['id'], data);
                }

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    fetchRoles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("OPERATION_FAILED")),
                    );
                  }
                }
              },
              child: Text("SAVE", style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: GoogleFonts.spaceMono(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
    );
  }

  void _deleteRole(Map<String, dynamic> role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text("DELETE_ROLE", style: GoogleFonts.righteous(color: Colors.redAccent)),
        content: Text("Delete \"${role['name']}\"?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("DELETE", style: GoogleFonts.spaceMono(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.deleteRole(role['id']);
    if (result['success'] == true) {
      fetchRoles();
    } else {
      final msg = result['message'] ?? 'DELETE_FAILED';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
    }
  }

  Widget _buildRoleCard(dynamic role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.mediumPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role['name'] ?? "N/A", style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 16)),
          const SizedBox(height: 5),
          Text(role['description'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () => _openRoleForm(role: role)),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () => _deleteRole(role)),
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
    if (_isLoading) {
      return const Scaffold(body: DynamicBackground(child: Center(child: CircularProgressIndicator(color: AppTheme.peach))));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Roles", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: fetchRoles)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.peach,
        onPressed: () => _openRoleForm(),
        child: const Icon(Icons.add, color: AppTheme.darkPurple),
      ),
      body: DynamicBackground(
        child: _roles.isEmpty
            ? const Center(child: Text("NO_ROLES_FOUND", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _roles.length,
                itemBuilder: (_, i) => _buildRoleCard(_roles[i]),
              ),
      ),
    );
  }
}
