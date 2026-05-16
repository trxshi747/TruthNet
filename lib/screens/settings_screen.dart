import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/screens/home_screen.dart';

import 'package:model2/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedFrequency = "INSTANT";
  bool _isEncryptionActive = true;

  void _showEditField(String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(title, style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.peach),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: Text("UPDATE", style: GoogleFonts.spaceMono(color: AppTheme.darkPurple)),
          ),
        ],
      ),
    );
  }

  void _showFrequencyDialog() {
    final options = ["INSTANT", "HOURLY", "DAILY", "DISABLED"];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text("ALERT_FREQUENCY_CONFIG", style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14)),
            trailing: _selectedFrequency == opt ? const Icon(Icons.check_circle, color: Color(0xFFF0C38E)) : null,
            onTap: () {
              setState(() => _selectedFrequency = opt);
              Navigator.pop(context);
              _showFeedback("FREQUENCY_SET_TO: $opt");
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text("CHANGE_ACCESS_KEY", style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(labelText: "OLD_KEY", labelStyle: GoogleFonts.spaceMono(color: Colors.white54)),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(labelText: "NEW_KEY", labelStyle: GoogleFonts.spaceMono(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await ApiService.updatePassword(auth.user!.id, oldController.text, newController.text);
              Navigator.pop(context);
              if (success) {
                _showFeedback("KEY_UPDATED_SUCCESSFULLY");
              } else {
                _showFeedback("UPDATE_FAILED: INCORRECT_KEY");
              }
            },
            child: Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SYSTEM_CONFIG", style: GoogleFonts.righteous()),
        backgroundColor: Colors.transparent,
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle("ACCOUNT_PROTOCOL"),
              _buildSettingTile(
                icon: Icons.person_outline,
                title: "IDENTITY_DETAILS",
                subtitle: user?.fullName ?? "UNKNOWN",
                onTap: () => _showEditField("UPDATE_NAME", user?.fullName ?? "", (val) async {
                  final nameParts = val.split(' ');
                  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
                  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
                  
                  final success = await ApiService.updateProfile(user!.id, firstName, lastName, user.bio ?? "", null);
                  if (success) {
                    authProvider.updateLocalProfile(firstName, lastName, user.bio ?? '');
                    profileKey.currentState?.fetchProfile();
                    _showFeedback("IDENTITY_SYNCED");
                  }
                }),
              ),
              _buildSettingTile(
                icon: Icons.email_outlined,
                title: "COMMUNICATION_LINK",
                subtitle: user?.email ?? "UNKNOWN",
                onTap: () => _showEditField("UPDATE_EMAIL", user?.email ?? "", (val) async {
                   final success = await ApiService.updateEmail(user!.id, val);
                   if (success) {
                     // Note: updateLocalEmail doesn't exist, we'll refactor this if needed.
                     // For now, the UI will update on next fetch.
                     _showFeedback("LINK_ESTABLISHED");
                   }
                }),
              ),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: "ACCESS_KEY_MODIFICATION",
                subtitle: "Update your password",
                onTap: _showPasswordDialog,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("APPLICATION_PARAMETERS"),
              _buildSettingTile(
                icon: _selectedFrequency == "DISABLED" ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
                title: "ALERT_FREQUENCIES",
                subtitle: "Current: $_selectedFrequency",
                onTap: _showFrequencyDialog,
              ),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                title: "INTERFACE_AESTHETICS",
                subtitle: "Default Cyber-Retro Theme",
                onTap: () => _showFeedback("THEME_LOCKED_BY_CORE"),
              ),
              _buildSettingTile(
                icon: _isEncryptionActive ? Icons.security : Icons.security_outlined,
                title: "PRIVACY_ENCRYPTION",
                subtitle: _isEncryptionActive ? "Data transmission secure" : "Encryption offline (Unsecured)",
                onTap: () {
                  setState(() => _isEncryptionActive = !_isEncryptionActive);
                  _showFeedback(_isEncryptionActive ? "ENCRYPTION_ENABLED" : "WARNING: ENCRYPTION_DISABLED");
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coral.withOpacity(0.2),
                  foregroundColor: AppTheme.coral,
                  side: const BorderSide(color: Color(0xFFF1AA9B)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  authProvider.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: Text("TERMINATE_SESSION", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 12)),
        backgroundColor: AppTheme.mediumPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
      child: Text(title, style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.coral),
        title: Text(title, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
