import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _useMock = false;

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getRoles();

      if (data.isEmpty) {
        _useMock = true;
        _roles = _mockRoles();
      } else {
        _useMock = false;
        _roles = data;
      }
    } catch (e) {
      _useMock = true;
      _roles = _mockRoles();
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _mockRoles() {
    return [
      {
        "id": "1",
        "name": "admin",
        "description": "Full access",
      },
      {
        "id": "2",
        "name": "moderator",
        "description": "Moderation access",
      },
    ];
  }

  Widget _buildRoleCard(dynamic role) {
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
          Text(
            role['name'] ?? "",
            style: GoogleFonts.righteous(
              color: const Color(0xFFF0C38E),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            role['description'] ?? "",
            style: GoogleFonts.spaceMono(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () {
                _openRoleForm(role: role);
              }),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () {
                _deleteRole(role['id']);
              }),
            ],
          )
        ],
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
        ),
      ),
    );
  }

  void _openRoleForm({Map<String, dynamic>? role}) {
    final nameController =
    TextEditingController(text: role?['name']);
    final descController =
    TextEditingController(text: role?['description']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF312C51),
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
              style: GoogleFonts.righteous(
                color: const Color(0xFFF0C38E),
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            _buildInput("ROLE NAME", nameController),
            _buildInput("DESCRIPTION", descController),

            const SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0C38E),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final data = {
                  "name": nameController.text,
                  "description": descController.text,
                };

                if (_useMock) {
                  setState(() {
                    if (role == null) {
                      _roles.add({"id": DateTime.now().toString(), ...data});
                    } else {
                      role.addAll(data);
                    }
                  });
                } else {
                  if (role == null) {
                    await ApiService.addRole(data);
                  } else {
                    await ApiService.updateRole(role['id'], data);
                  }

                  fetchRoles();
                }

                Navigator.pop(context);
              },
              child: Text(
                "SAVE",
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF312C51),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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

  void _deleteRole(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: const Text("Delete this role?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    if (_useMock) {
      setState(() {
        _roles.removeWhere((r) => r['id'] == id);
      });
    } else {
      await ApiService.deleteRole(id);
      fetchRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      /*return const Scaffold(
        body: DynamicBackground(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF0C38E)),
          ),
        ),
      ); */
      return Scaffold(
        appBar: AppBar(title: const Text("User Management")),

        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFF0C38E),
          onPressed: () => _openRoleForm(), // 🔥 ouvre le formulaire
          child: const Icon(Icons.add, color: Color(0xFF312C51)),
        ),

        body: DynamicBackground(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _roles.length,
            itemBuilder: (context, index) {
              return _buildRoleCard(_roles[index]);
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("User Management")),
      body: DynamicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _roles.length,
          itemBuilder: (context, index) {
            return _buildRoleCard(_roles[index]);
          },
        ),
      ),
    );
  }

}