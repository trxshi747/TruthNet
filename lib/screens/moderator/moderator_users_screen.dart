import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import 'package:model2/core/theme/app_theme.dart';

class ModeratorUsersScreen extends StatefulWidget {
  const ModeratorUsersScreen({super.key});

  @override
  State<ModeratorUsersScreen> createState() => _ModeratorUsersScreenState();
}

class _ModeratorUsersScreenState extends State<ModeratorUsersScreen> {
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
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  // ============ SANCTION ACTIONS WITH DATE/TIME PICKER ============

  Future<void> _showSuspendModal(dynamic user) async {
    final TextEditingController reasonController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 0, minute: 0);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final displayDate = DateFormat('yyyy-MM-dd').format(selectedDate);
          final displayTime = selectedTime.format(context);

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
                  "User: ${user['name'] ?? user['username']}",
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
                const SizedBox(height: 20),
                Text(
                  "END DATE & TIME",
                  style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null) {
                            setModalState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(displayDate, style: GoogleFonts.spaceMono(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setModalState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(displayTime, style: GoogleFonts.spaceMono(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
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

                    final finalEndDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (finalEndDateTime.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("END_DATE_MUST_BE_IN_FUTURE")),
                        );
                        return;
                    }

                    try {
                      final adminId = auth.user?.id ?? 'UNKNOWN_ADMIN';
                      debugPrint('Suspending user: ${user['id']} by admin: $adminId');
                      
                      final success = await ApiService.suspendUser(
                        userId: user['id'],
                        reason: reasonController.text,
                        endDate: finalEndDateTime.toIso8601String(),
                        adminId: adminId,
                        durationDays: 1,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        if (success) {
                          fetchUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("USER_SUSPENDED")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("ACTION_FAILED_BY_SERVER")),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Suspension error: $e');
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("ERROR: $e")),
                        );
                      }
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
                  "User: ${user['name'] ?? user['username']}",
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

                    try {
                        final success = await ApiService.banUser(
                          userId: user['id'],
                          reason: reasonController.text,
                          adminId: auth.user!.id,
                        );

                        if (mounted) {
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
                        }
                    } catch(e) {
                         if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("ERROR: $e")),
                            );
                         }
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(
          "LIFT SANCTION",
          style: GoogleFonts.righteous(color: Colors.green),
        ),
        content: Text(
          "RESTORE ACCESS FOR ${user['username']?.toUpperCase()}?",
          style: GoogleFonts.spaceMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("RESTORE", style: GoogleFonts.spaceMono(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.activateUser(
          userId: user['id'], 
          adminId: auth.user?.id ?? 'SYSTEM'
      );
      if (success) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("USER_ACCESS_RESTORED")),
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
    String expiryText = "N/A";
    if (sanction['endDate'] != null) {
        try {
            final date = DateTime.parse(sanction['endDate']);
            expiryText = DateFormat('yyyy-MM-dd HH:mm').format(date);
        } catch(e) {
            expiryText = sanction['endDate'].toString();
        }
    }

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
              'Until: $expiryText',
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
        if (status == 'SUSPENDED' || status == 'INACTIVE' || status == 'BANNED')
          _actionButton('LIFT SANCTION', Colors.green, () => _showActivateModal(user)),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final profile = user['profile'] as Map<String, dynamic>?;
    final isSanctioned = user['activeSanction'] != null;
    final status = (user['status'] ?? 'ACTIVE').toString().toUpperCase();

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
                      user['firstName'] != null && user['lastName'] != null
                          ? "${user['firstName']} ${user['lastName']}"
                          : user['name'] ?? 'UNKNOWN',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: DynamicBackground(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF0C38E)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Users & Sanctions", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.peach),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.peach),
            onPressed: fetchUsers,
          ),
        ],
      ),
      body: DynamicBackground(
        child: _users.isEmpty
            ? Center(
          child: Text(
            "NO_USERS_FOUND",
            style: GoogleFonts.spaceMono(color: Colors.white54),
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
