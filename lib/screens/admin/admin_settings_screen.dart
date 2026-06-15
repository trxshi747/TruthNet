import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/services/dashboard_service.dart';
import 'package:provider/provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _aiOnline = false;
  bool _loadingHealth = true;
  bool _saving = false;

  bool _strictModeration = true;
  bool _autoFactCheck = true;
  bool _emailAlerts = true;
  bool _maintenanceMode = false;
  double _truthWarningThreshold = 0.40;
  String _alertFrequency = 'Instant';

  static const _textPri = Color(0xFFF0F2F5);
  static const _textSec = Color(0xFF7B8499);
  static const _red = Color(0xFFEE2727);
  static const _amber = Color(0xFFFFCF26);

  @override
  void initState() {
    super.initState();
    _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    if (!mounted) return;
    setState(() => _loadingHealth = true);
    final aiOnline = await DashboardService.isAIServiceAvailable();
    if (!mounted) return;
    setState(() {
      _aiOnline = aiOnline;
      _loadingHealth = false;
    });
  }

  Future<void> _updateEmail(User user) async {
    final controller = TextEditingController(text: user.email);
    final nextEmail = await _showTextDialog(
      title: 'Update Admin Email',
      label: 'Email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
    );
    if (nextEmail == null || nextEmail == user.email) return;

    setState(() => _saving = true);
    final success = await ApiService.updateEmail(user.id, nextEmail);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      context.read<AuthProvider>().updateLocalEmail(nextEmail);
      _showFeedback('Email updated');
    } else {
      _showFeedback('Email update failed', isError: true);
    }
  }

  Future<void> _changePassword(User user) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(
          'Change Password',
          style: GoogleFonts.righteous(color: AppTheme.peach),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput('Current password', oldController, obscure: true),
            const SizedBox(height: 14),
            _dialogInput('New password', newController, obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceMono(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.peach),
            onPressed: () => Navigator.pop(context, [
              oldController.text.trim(),
              newController.text.trim(),
            ]),
            child: Text(
              'Update',
              style: GoogleFonts.spaceMono(color: AppTheme.darkPurple),
            ),
          ),
        ],
      ),
    );

    if (values == null || values[0].isEmpty || values[1].isEmpty) return;

    setState(() => _saving = true);
    final success = await ApiService.updatePassword(
      user.id,
      values[0],
      values[1],
    );
    if (!mounted) return;
    setState(() => _saving = false);

    _showFeedback(
      success ? 'Password updated' : 'Password update failed',
      isError: !success,
    );
  }

  Future<String?> _showTextDialog({
    required String title,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        title: Text(title, style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: _dialogInput(label, controller, keyboardType: keyboardType),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceMono(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.peach),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.spaceMono(color: AppTheme.darkPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.spaceMono(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceMono(color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.peach),
        ),
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceMono(color: Colors.white),
        ),
        backgroundColor: isError ? _red : AppTheme.mediumPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: GoogleFonts.righteous(color: AppTheme.peach),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.peach,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh health',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _refreshHealth,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.peach,
        onRefresh: _refreshHealth,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Account'),
            const SizedBox(height: 10),
            _AdminProfileCard(
              user: user,
              onUpdateEmail: user == null ? null : () => _updateEmail(user),
              onChangePassword: user == null
                  ? null
                  : () => _changePassword(user),
            ),
            const SizedBox(height: 24),
            _sectionTitle('AI service'),
            const SizedBox(height: 10),
            _HealthCard(
              aiOnline: _aiOnline,
              loading: _loadingHealth,
              onRefresh: _refreshHealth,
            ),
            /*
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SwitchSettingTile(
                  icon: Icons.fact_check_rounded,
                  title: 'Automatic fact-checking',
                  subtitle: 'Verify new posts before publication.',
                  value: _autoFactCheck,
                  onChanged: (value) => setState(() => _autoFactCheck = value),
                ),
                _SwitchSettingTile(
                  icon: Icons.policy_rounded,
                  title: 'Strict moderation mode',
                  subtitle: 'Surface low-trust and toxic content sooner.',
                  value: _strictModeration,
                  onChanged: (value) =>
                      setState(() => _strictModeration = value),
                ),
                /*
                _SwitchSettingTile(
                  icon: Icons.construction_rounded,
                  title: 'Maintenance mode',
                  subtitle: 'Temporarily limit member publishing.',
                  value: _maintenanceMode,
                  danger: true,
                  onChanged: (value) =>
                      setState(() => _maintenanceMode = value),
                ),*/
              ],
            ),*/
            /*
            const SizedBox(height: 24),
            _sectionTitle('Alerts'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SwitchSettingTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email alerts',
                  subtitle: 'Notify admins when intervention is needed.',
                  value: _emailAlerts,
                  onChanged: (value) => setState(() => _emailAlerts = value),
                ),
                _SelectSettingTile(
                  icon: Icons.schedule_rounded,
                  title: 'Alert frequency',
                  subtitle: _alertFrequency,
                  options: const ['Instant', 'Hourly', 'Daily', 'Disabled'],
                  onSelected: (value) =>
                      setState(() => _alertFrequency = value),
                ),
              ],
            ),
            */
            const SizedBox(height: 24),
            _sectionTitle('Truthness'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: _amber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Low-trust warning threshold',
                              style: GoogleFonts.spaceMono(
                                color: _textPri,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${(_truthWarningThreshold * 100).round()}%',
                            style: GoogleFonts.righteous(
                              color: AppTheme.peach,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posts below this score are highlighted for review.',
                        style: GoogleFonts.spaceMono(
                          color: _textSec,
                          fontSize: 11,
                        ),
                      ),
                      Slider(
                        value: _truthWarningThreshold,
                        min: 0.10,
                        max: 0.80,
                        divisions: 14,
                        activeColor: AppTheme.peach,
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          setState(() => _truthWarningThreshold = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.righteous(color: _textPri, fontSize: 20),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final User? user;
  final VoidCallback? onUpdateEmail;
  final VoidCallback? onChangePassword;

  const _AdminProfileCard({
    required this.user,
    required this.onUpdateEmail,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.peach.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.peach.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.peach,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName.trim().isNotEmpty == true
                          ? user!.fullName
                          : 'Admin',
                      style: GoogleFonts.righteous(
                        color: const Color(0xFFF0F2F5),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${user?.displayName ?? '@admin'} · ${user?.email ?? 'No email'}',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF7B8499),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ActionSettingTile(
          icon: Icons.email_outlined,
          title: 'Admin email',
          subtitle: user?.email ?? 'Not available',
          onTap: onUpdateEmail,
        ),
        _ActionSettingTile(
          icon: Icons.lock_outline_rounded,
          title: 'Password',
          subtitle: 'Change your admin password.',
          onTap: onChangePassword,
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final bool aiOnline;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _HealthCard({
    required this.aiOnline,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final color = aiOnline ? const Color(0xFF2ECC71) : const Color(0xFFEE2727);

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI service',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFF0F2F5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? 'Checking service status...'
                          : aiOnline
                          ? 'Online and ready for moderation analysis.'
                          : 'Offline. Start the AI service to restore analysis.',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF7B8499),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppTheme.peach,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252D3D)),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool danger;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFEE2727) : AppTheme.peach;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.spaceMono(
          color: const Color(0xFFF0F2F5),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceMono(
          color: const Color(0xFF7B8499),
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ActionSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppTheme.peach),
      title: Text(
        title,
        style: GoogleFonts.spaceMono(
          color: const Color(0xFFF0F2F5),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceMono(
          color: const Color(0xFF7B8499),
          fontSize: 11,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: onTap,
    );
  }
}

class _SelectSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _SelectSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppTheme.darkPurple,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: Text(
              option,
              style: GoogleFonts.spaceMono(color: Colors.white),
            ),
          ),
      ],
      child: _ActionSettingTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: null,
      ),
    );
  }
}
