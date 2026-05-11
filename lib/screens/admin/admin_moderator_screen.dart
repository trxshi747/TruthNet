import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({Key? key}) : super(key: key);

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  List<dynamic> _moderators = [];
  bool _isLoading = true;
  bool _useMock = false;

  // Options pour les dropdowns
  final List<String> _statusOptions = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];
  final List<String> _roleOptions = ['Moderator', 'Member','Admin']; // On ne peut pas promouvoir en Admin ici

  @override
  void initState() {
    super.initState();
    fetchModerators();
  }

  Future<void> fetchModerators() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getModerators();

      if (data.isEmpty) {
        _useMock = true;
        _moderators = _mockModerators();
      } else {
        _useMock = false;
        _moderators = data;
      }
    } catch (e) {
      _useMock = true;
      _moderators = _mockModerators();
    }

    setState(() => _isLoading = false);
  }

  //mock data when to see the display format
  List<Map<String, dynamic>> _mockModerators() {
    return [
      {
        "id": "1",
        "name": "Mod",
        "username": "modalpha",
        "email": "mod1@mail.com",
        "status": "active",
        "role": "moderator",
      },
      {
        "id": "2",
        "name": "Beta",
        "username": "modbeta",
        "email": "mod2@mail.com",
        "status": "inactive",
        "role": "moderator",
      },
    ];
  }

  // ---------- ADD / EDIT MODAL ----------
/*
  void _openModeratorForm({Map<String, dynamic>? moderator}) {
    final nameController = TextEditingController(text: moderator?['name']);
    final emailController = TextEditingController(text: moderator?['email']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF312C51),
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
              moderator == null ? "ADD_MODERATOR" : "EDIT_MODERATOR",
              style: GoogleFonts.righteous(
                color: const Color(0xFFF0C38E),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "FIRST NAME",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "LAST NAME",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "USERNAME",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "EMAIL",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "PASSWORD",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "STATUS",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "ROLE",
                labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0C38E),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (moderator == null) {
                  // ADD
                  await ApiService.addModerator(
                    nameController.text,
                    emailController.text,
                  );

                  setState(() {
                    _moderators.add({
                      "id": DateTime.now().toString(),
                      "name": nameController.text,
                      "email": emailController.text,
                    });
                  });
                } else {
                  // UPDATE
                  await ApiService.updateModerator(
                    moderator['id'],
                    nameController.text,
                    emailController.text,
                  );

                  setState(() {
                    moderator['name'] = nameController.text;
                    moderator['email'] = emailController.text;
                  });
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
*/

  /*
  void _openModeratorForm({Map<String, dynamic>? moderator}) {
    final nameController = TextEditingController(text: moderator?['name']);
    final usernameController = TextEditingController(text: moderator?['username']);
    final emailController = TextEditingController(text: moderator?['email']);
    final passwordController = TextEditingController();
    final statusController = TextEditingController(text: moderator?['status'] ?? "Active");
    final roleController = TextEditingController(text: moderator?['role'] ?? "Moderator");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF312C51),
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
        child: SingleChildScrollView( //  important pour éviter overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                moderator == null ? "ADD_MODERATOR" : "EDIT_MODERATOR",
                style: GoogleFonts.righteous(
                  color: const Color(0xFFF0C38E),
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 20),

              _buildInput("NAME", nameController),
              _buildInput("USERNAME", usernameController),
              _buildInput("EMAIL", emailController),
              _buildInput("PASSWORD", passwordController, obscure: true),
              _buildInput("STATUS", statusController),
              _buildInput("ROLE", roleController),

              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C38E),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  // 🔥 VALIDATION
                  if (nameController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      emailController.text.isEmpty) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("FILL_REQUIRED_FIELDS")),
                    );
                    return;
                  }

                  final data = {
                    "name": nameController.text,
                    "username": usernameController.text,
                    "email": emailController.text,
                    "password": passwordController.text,
                    "status": statusController.text,
                    "role": roleController.text,
                  };

                  //forcing the usage of api instead of mock (trial!)
                  _useMock = false;
                  if (_useMock) {
                    // MOCK MODE
                    setState(() {
                      if (moderator == null) {
                        _moderators.add({
                          "id": DateTime.now().toString(),
                          ...data,
                        });
                      } else {
                        moderator.addAll(data);
                      }
                    });
                  } else {
                    // API MODE
                    if (moderator == null) {
                      await ApiService.addModerator(data);
                    } else {
                      // this update should be carful ! might cause data loss
                      await ApiService.updateModerator(
                        moderator['id'],
                        data,
                      );
                    }

                    fetchModerators();
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  */

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
        dropdownColor: const Color(0xFF48426D),
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
            child: Text(
              option,
              style: GoogleFonts.spaceMono(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }


  void _openModeratorForm({Map<String, dynamic>? moderator}) {
    final nameController = TextEditingController(text: moderator?['name'] ?? '');
    final usernameController = TextEditingController(text: moderator?['username'] ?? '');
    final emailController = TextEditingController(text: moderator?['email'] ?? '');
    final passwordController = TextEditingController();

    // Valeurs par défaut pour les dropdowns
    String selectedStatus = moderator?['status']?.toString().toUpperCase() ?? 'ACTIVE';
    String selectedRole = moderator?['role'] ?? 'Moderator';

    // S'assurer que la valeur est valide
    if (!_statusOptions.contains(selectedStatus)) selectedStatus = 'ACTIVE';
    if (!_roleOptions.contains(selectedRole)) selectedRole = 'Moderator';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF312C51),
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
                      color: const Color(0xFFF0C38E),
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NAME
                  _buildInput("NAME", nameController),

                  // USERNAME
                  _buildInput("USERNAME", usernameController),

                  // EMAIL
                  _buildInput("EMAIL", emailController),

                  // PASSWORD (only show when adding new moderator)
                  if (moderator == null)
                    _buildInput("PASSWORD", passwordController, obscure: true),

                  // STATUS (Dropdown)
                  _buildDropdown(
                    label: "STATUS",
                    value: selectedStatus,
                    options: _statusOptions,
                    onChanged: (value) {
                      setModalState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),

                  // ROLE (Dropdown)
                  _buildDropdown(
                    label: "ROLE",
                    value: selectedRole,
                    options: _roleOptions,
                    onChanged: (value) {
                      setModalState(() {
                        selectedRole = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0C38E),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      // VALIDATION
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

                      if (moderator == null) {
                        await ApiService.addModerator(data);
                      } else {
                        await ApiService.updateModerator(moderator['id'], data);
                      }

                      Navigator.pop(context);
                      fetchModerators();
                    },
                    child: Text(
                      "SAVE",
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF312C51),
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

  /*
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
  */

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

  // ============ CHANGE STATUS DIRECTLY FROM CARD ============
  void _changeStatus(dynamic moderator, String newStatus) async {
    final data = {
      "name": moderator['name'],
      "username": moderator['username'],
      "email": moderator['email'],
      "status": newStatus,
      "role": moderator['role'],
    };

    await ApiService.updateModerator(moderator['id'], data);
    fetchModerators();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("STATUS_CHANGED_TO_$newStatus")),
    );
  }

  // ---------- DELETE ----------

  /*
  void _deleteModerator(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF312C51),
        title: Text("DELETE_MODERATOR",
            style: GoogleFonts.righteous(color: Colors.redAccent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL",
                style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("DELETE",
                style: GoogleFonts.spaceMono(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // again ... let's assume we don't use mocks
    if (_useMock) {
      setState(() {
        _moderators.removeWhere((m) => m['id'] == id);
      });
    } else {
      await ApiService.deleteModerator(id);
      fetchModerators();
    }
  }
  */

  void _deleteModerator(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF312C51),
        title: Text(
          "DELETE_MODERATOR",
          style: GoogleFonts.righteous(color: Colors.redAccent),
        ),
        content: Text(
          "THIS_ACTION_CANNOT_BE_UNDONE",
          style: GoogleFonts.spaceMono(color: Colors.white70),
        ),
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

    await ApiService.deleteModerator(id);
    fetchModerators();
  }


  // ---------- UI CARD ----------

  /*
  Widget _buildModeratorCard(dynamic mod) {
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
          Text(mod['name'] ?? "N/A",
              style: GoogleFonts.righteous(color: const Color(0xFFF0C38E))),
          const SizedBox(height: 5),
          Text(mod['username'] ?? "N/A",
              style: GoogleFonts.righteous(color: const Color(0xFFF0C38E))),
          const SizedBox(height: 5),
          Text(mod['email'] ?? "N/A",
              style: GoogleFonts.righteous(color: const Color(0xFFF0C38E))),
          const SizedBox(height: 5),
          Text("PASSWORD: HIDDEN",
              style: GoogleFonts.spaceMono(color: Colors.white38)),
          const SizedBox(height: 5),
          Text(mod['status'] ?? "unknown",
              style: GoogleFonts.spaceMono(color: Colors.white70)),

          const SizedBox(height: 10),

          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () {
                _openModeratorForm(moderator: mod);
              }),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () {
                _deleteModerator(mod['id']);
              }),
            ],
          )
        ],
      ),
    );
  }
  */

  Widget _buildModeratorCard(dynamic mod) {
    // Couleur du badge de statut
    Color statusColor;
    switch (mod['status']?.toString().toUpperCase()) {
      case 'ACTIVE':
        statusColor = Colors.green;
        break;
      case 'INACTIVE':
        statusColor = Colors.grey;
        break;
      case 'SUSPENDED':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

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
          // En-tête avec nom et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mod['name'] ?? "N/A",
                  style: GoogleFonts.righteous(
                    color: const Color(0xFFF0C38E),
                    fontSize: 16,
                  ),
                ),
              ),
              // Badge de statut avec dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: DropdownButton<String>(
                  value: mod['status']?.toString().toUpperCase() ?? 'ACTIVE',
                  dropdownColor: const Color(0xFF48426D),
                  underline: const SizedBox(),
                  style: GoogleFonts.spaceMono(
                    color: statusColor,
                    fontSize: 10,
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
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

          // Username
          Text(
            "@${mod['username'] ?? 'unknown'}",
            style: GoogleFonts.spaceMono(
              color: const Color(0xFFF1AA9B),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 5),

          // Email
          Text(
            mod['email'] ?? "N/A",
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0C38E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF0C38E).withOpacity(0.5)),
            ),
            child: Text(
              mod['role']?.toString().toUpperCase() ?? 'MODERATOR',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFF0C38E),
                fontSize: 9,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Actions buttons
          Row(
            children: [
              _actionButton("EDIT", Colors.blue, () {
                _openModeratorForm(moderator: mod);
              }),
              const SizedBox(width: 10),
              _actionButton("DELETE", Colors.red, () {
                _deleteModerator(mod['id']);
              }),
            ],
          )
        ],
      ),
    );
  }

  /*
  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(label,
            style: GoogleFonts.spaceMono(color: color, fontSize: 10)),
      ),
    );
  }
  */

  // Dans AdminModeratorsScreen - La méthode _changeRole

  Future<void> _changeRole(dynamic moderator, String newRole) async {
    // Ne rien faire si le rôle n'a pas changé
    if (newRole == moderator['role']) return;

    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("UPDATING_ROLE...")),
    );

    final data = {
      "name": moderator['name'],
      "username": moderator['username'],
      "email": moderator['email'],
      "status": moderator['status'],
      "role": newRole,  // Le nouveau rôle (Member ou Moderator)
    };

    final success = await ApiService.updateModerator(moderator['id'], data);

    if (success) {
      fetchModerators();  // Recharge la liste
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ROLE_CHANGED_TO_${newRole.toUpperCase()}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FAILED_TO_CHANGE_ROLE")),
      );
    }
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
        child: Text(
          label,
          style: GoogleFonts.spaceMono(color: color, fontSize: 10),
        ),
      ),
    );
  }

  // ---------- BUILD ----------

  /*
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
      appBar: AppBar(title: const Text("Moderators")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF0C38E),
        onPressed: () => _openModeratorForm(),
        child: const Icon(Icons.add, color: Color(0xFF312C51)),
      ),
      body: DynamicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _moderators.length,
          itemBuilder: (_, i) => _buildModeratorCard(_moderators[i]),
        ),
      ),
    );
  }
  */

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
      appBar: AppBar(
        title: const Text("Moderators"),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchModerators,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF0C38E),
        onPressed: () => _openModeratorForm(),
        child: const Icon(Icons.add, color: Color(0xFF312C51)),
      ),
      body: DynamicBackground(
        child: _moderators.isEmpty
            ? const Center(
          child: Text(
            "NO_MODERATORS_FOUND",
            style: TextStyle(color: Colors.white54),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _moderators.length,
          itemBuilder: (_, i) => _buildModeratorCard(_moderators[i]),
        ),
      ),
    );
  }
}

