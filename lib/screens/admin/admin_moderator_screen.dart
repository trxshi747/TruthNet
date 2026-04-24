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
  // ---------- DELETE ----------

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
  // ---------- UI CARD ----------

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

  // ---------- BUILD ----------

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
}