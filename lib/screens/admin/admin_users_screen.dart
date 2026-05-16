import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

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

  /*
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
  */

  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getAllUsers();
      debugPrint('✅ Users reçus: ${users.length}');

      // Plus de fallback mock — on voit les vraies erreurs
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _mockUsers() {
    return [
      {
        "id": "1",
        "name": "Alice Johnson",
        "email": "alice@mail.com",
        "role": "user",
        "status": "ACTIVE",
        "activeSanction": null,
      },
      {
        "id": "2",
        "name": "Test User",
        "email": "test@mail.com",
        "role": "user",
        "status": "ACTIVE",
        "activeSanction": null,
      },
      {
        "id": "3",
        "name": "Lilly Bolossom",
        "email": "lilly@mail.com",
        "role": "user",
        "status": "SUSPENDED",
        "activeSanction": {
          "type": "SUSPENSION",
          "reason": "Spamming",
          "endDate": "2024-12-01T00:00:00Z"
        },
      },
    ];
  }


  // ============ SANCTION ACTIONS WITH REASON MODAL ============

  Future<void> _showSuspendModal(dynamic user) async {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController daysController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "SUSPEND USER",
                    style: GoogleFonts.righteous(
                      color: AppTheme.peach,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "User: ${user['name']}",
                  style: GoogleFonts.spaceMono(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  style: GoogleFonts.spaceMono(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "REASON FOR SUSPENSION",
                    labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: daysController,
                  style: GoogleFonts.spaceMono(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "DURATION (DAYS)",
                    labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("REASON_REQUIRED")),
                      );
                      return;
                    }

                    final days = int.tryParse(daysController.text);
                    if (days == null || days <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("VALID_DURATION_REQUIRED")),
                      );
                      return;
                    }

                    final success = await ApiService.suspendUser(
                      userId: user['id'],
                      reason: reasonController.text,
                      durationDays: days,
                      adminId: auth.user!.id,
                    );

                    Navigator.pop(context);
                    if (success) {
                      fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("USER_SUSPENDED_FOR_${days}_DAYS")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ACTION_FAILED")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.peach,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(
                    "CONFIRM SUSPENSION",
                    style: GoogleFonts.spaceMono(color: AppTheme.darkPurple),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBanModal(dynamic user) async {
    final TextEditingController reasonController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "PERMANENT BAN",
                    style: GoogleFonts.righteous(
                      color: Colors.redAccent,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "User: ${user['name']}",
                  style: GoogleFonts.spaceMono(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  style: GoogleFonts.spaceMono(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "REASON FOR BAN",
                    labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("REASON_REQUIRED")),
                      );
                      return;
                    }

                    final success = await ApiService.banUser(
                      userId: user['id'],
                      reason: reasonController.text,
                      adminId: auth.user!.id,
                    );

                    Navigator.pop(context);
                    if (success) {
                      fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("USER_PERMANENTLY_BANNED")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ACTION_FAILED")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(
                    "CONFIRM BAN",
                    style: GoogleFonts.spaceMono(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showActivateModal(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(
          "ACTIVATE USER",
          style: GoogleFonts.righteous(color: Colors.green),
        ),
        content: Text(
          "REACTIVATE ${user['name']?.toUpperCase()}?",
          style: GoogleFonts.spaceMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("ACTIVATE", style: GoogleFonts.spaceMono(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.activateUser(user['id']);
      if (success) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("USER_ACTIVATED")),
        );
      }
    }
  }

  // ============ UI COMPONENTS ============

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUSPENDED':
        return Colors.orange;
      case 'BANNED':
        return Colors.red;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUSPENDED':
        return 'SUSPENDED';
      case 'BANNED':
        return 'BANNED';
      case 'INACTIVE':
        return 'INACTIVE';
      default:
        return 'ACTIVE';
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceMono(
          color: _getStatusColor(status),
          fontSize: 9,
        ),
      ),
    );
  }


  Widget _sanctionBadge(Map<String, dynamic> sanction) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sanction: ${sanction['type']}',
            style: GoogleFonts.spaceMono(
              color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold,
            ),
          ),
          if (sanction['reason'] != null)
            Text(
              'Reason: ${sanction['reason']}',
              style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 9),
            ),
          if (sanction['endDate'] != null)
            Text(
              'Until: ${sanction['endDate'].toString().substring(0, 10)}',
              style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 9),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic user, String status) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status != 'SUSPENDED' && status != 'BANNED')
          _actionButton('SUSPEND', Colors.orange, () => _showSuspendModal(user)),
        if (status != 'BANNED')
          _actionButton('BAN', Colors.redAccent, () => _showBanModal(user)),
        if (status == 'SUSPENDED' || status == 'INACTIVE')
          _actionButton('ACTIVATE', Colors.green, () => _showActivateModal(user)),
        if (status == 'ACTIVE')
          _actionButton('DEACTIVATE', Colors.grey, () => _confirmAction(
            'DEACTIVATE USER?',
            colors: Colors.grey,
            action: () => ApiService.deactivateUser(user['id']),
          )),
        _actionButton('DELETE', Colors.red, () => _confirmAction(
          'DELETE USER PERMANENTLY?\nThis cannot be undone!',
          colors: Colors.red,
          action: () => ApiService.deleteUser(user['id']),
        )),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final profile = user['profile'] as Map<String, dynamic>?;
    final isSanctioned = user['activeSanction'] != null;
    final status = (user['status'] ?? 'ACTIVE').toString().toUpperCase(); // ← toUpperCase() important

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: isSanctioned ? Border.all(color: Colors.orange) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'UNKNOWN',
                      style: GoogleFonts.righteous(
                        color: AppTheme.peach,
                        fontSize: 16,
                      ),
                    ),
                    if (user['username'] != null)
                      Text(
                        '@${user['username']}',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 5),
          Text(
            user['email'] ?? '',
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'Role: ${user['role'] ?? 'Member'}',
            style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 10),
          ),

          if (profile?['bio']?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              profile!['bio'],
              style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (isSanctioned) _sanctionBadge(user['activeSanction']),

          const SizedBox(height: 10),
          _buildActionButtons(user, status),
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
        child: Text(
          label,
          style: GoogleFonts.spaceMono(color: color, fontSize: 10),
        ),
      ),
    );
  }

  Future<void> _confirmAction(
      String message, {
        required Color colors,
        required Future<void> Function() action,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(
          message,
          style: GoogleFonts.righteous(color: colors),
        ),
        content: Text(
          "This action will affect the user's account.",
          style: GoogleFonts.spaceMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("CONFIRM", style: GoogleFonts.spaceMono(color: colors)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
      fetchUsers();
    }
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
      appBar: AppBar(
        title: const Text("User Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUsers,
          ),
        ],
      ),
      body: DynamicBackground(
        child: _users.isEmpty
            ? const Center(
          child: Text(
            "NO_USERS_FOUND",
            style: TextStyle(color: Colors.white54),
          ),
        )
            : ListView.builder(
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
