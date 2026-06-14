import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({super.key});

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  List<dynamic> _moderators = [];
  bool _isLoading = true;

  final List<String> _statusOptions = ['ACTIVE', 'INACTIVE'];
  final List<String> _roleOptions = ['Moderator', 'Member', 'Admin'];

  @override
  void initState() {
    super.initState();
    fetchModerators();
  }

  Future<void> fetchModerators() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getModerators();
      if (mounted) {
        setState(() {
          _moderators = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moderators = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openModeratorForm({Map<String, dynamic>? moderator}) {
    final nameController = TextEditingController(text: moderator?['name'] ?? '');
    final usernameController = TextEditingController(text: moderator?['username'] ?? '');
    final emailController = TextEditingController(text: moderator?['email'] ?? '');
    final passwordController = TextEditingController();

    String selectedStatus = moderator?['status']?.toString().toUpperCase() ?? 'ACTIVE';
    String selectedRole = moderator?['role'] ?? 'Moderator';

    if (!_statusOptions.contains(selectedStatus)) selectedStatus = 'ACTIVE';
    if (!_roleOptions.contains(selectedRole)) selectedRole = 'Moderator';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                    moderator == null ? "ADD_MODERATOR" : "EDIT_MODERATOR",
                    style: GoogleFonts.righteous(
                      color: AppTheme.peach,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInput("NAME", nameController),
                  _buildInput("USERNAME", usernameController),
                  _buildInput("EMAIL", emailController),
                  if (moderator == null)
                    _buildInput("PASSWORD", passwordController, obscure: true),
                  _buildDropdown(
                    label: "STATUS",
                    value: selectedStatus,
                    options: _statusOptions,
                    onChanged: (value) {
                      setModalState(() => selectedStatus = value!);
                    },
                  ),
                  _buildDropdown(
                    label: "ROLE",
                    value: selectedRole,
                    options: _roleOptions,
                    onChanged: (value) {
                      setModalState(() => selectedRole = value!);
                    },
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.peach,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          usernameController.text.isEmpty ||
                          emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("FILL_REQUIRED_FIELDS")),
                        );
                        return;
                      }
                      if (moderator == null && passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PASSWORD_REQUIRED")),
                        );
                        return;
                      }

                      final data = {
                        "name": nameController.text,
                        "username": usernameController.text,
                        "email": emailController.text,
                        "status": selectedStatus,
                        "role": selectedRole,
                      };

                      if (moderator == null) {
                        data["password"] = passwordController.text;
                      }

                      Map<String, dynamic> result;
                      if (moderator == null) {
                        result = await ApiService.addModerator(data);
                      } else {
                        result = await ApiService.updateModerator(moderator['id'], data);
                      }

                      if (mounted) {
                        if (result['success'] == true) {
                          Navigator.pop(context);
                          fetchModerators();
                        } else {
                          final message = result['message'] ?? "OPERATION_FAILED";
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      "SAVE",
                      style: GoogleFonts.spaceMono(
                        color: AppTheme.darkPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
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
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppTheme.mediumPurple,
        style: GoogleFonts.spaceMono(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option, style: GoogleFonts.spaceMono(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _changeStatus(dynamic moderator, String newStatus) async {
    final data = {
      "name": moderator['name'],
      "username": moderator['username'],
      "email": moderator['email'],
      "status": newStatus,
      "role": moderator['role'],
    };

    final result = await ApiService.updateModerator(moderator['id'], data);
    if (result['success'] == true) {
      fetchModerators();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("STATUS_CHANGED_TO_$newStatus")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "UPDATE_FAILED"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteModerator(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text("DELETE_MODERATOR", style: GoogleFonts.righteous(color: Colors.redAccent)),
        content: Text("THIS_ACTION_CANNOT_BE_UNDONE", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("DELETE", style: GoogleFonts.spaceMono(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.deleteModerator(id);
    if (result['success'] == true) {
      fetchModerators();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "DELETE_FAILED"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildModeratorCard(dynamic mod) {
    Color statusColor;
    switch (mod['status']?.toString().toUpperCase()) {
      case 'ACTIVE': statusColor = Colors.green; break;
      case 'INACTIVE': statusColor = Colors.grey; break;
      case 'SUSPENDED': statusColor = Colors.orange; break;
      default: statusColor = Colors.grey;
    }

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
                  mod['name'] ?? "N/A",
                  style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: DropdownButton<String>(
                  value: mod['status']?.toString().toUpperCase() ?? 'ACTIVE',
                  dropdownColor: AppTheme.mediumPurple,
                  underline: const SizedBox(),
                  style: GoogleFonts.spaceMono(color: statusColor, fontSize: 10),
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null && newStatus != mod['status']) {
                      _changeStatus(mod, newStatus);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("@${mod['username'] ?? 'unknown'}", style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 11)),
          const SizedBox(height: 5),
          Text(mod['email'] ?? "N/A", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.peach.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.peach.withOpacity(0.5)),
            ),
            child: Text(
              mod['role']?.toString().toUpperCase() ?? 'MODERATOR',
              style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 9),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () => _openModeratorForm(moderator: mod)),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () => _deleteModerator(mod['id'])),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: DynamicBackground(child: Center(child: CircularProgressIndicator(color: AppTheme.peach))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Moderator Management", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchModerators),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.peach,
        onPressed: () => _openModeratorForm(),
        child: const Icon(Icons.add, color: AppTheme.darkPurple),
      ),
      body: DynamicBackground(
        child: _moderators.isEmpty
            ? const Center(child: Text("NO_MODERATORS_FOUND", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _moderators.length,
                itemBuilder: (_, i) => _buildModeratorCard(_moderators[i]),
              ),
      ),
    );
  }
}
