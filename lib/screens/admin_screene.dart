import 'package:flutter/material.dart';

import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_moderator_screen.dart';
import 'admin/admin_role_screen.dart';
import 'admin/admin_users_screen.dart';

// ─── Design Tokens (BusTrack-inspired) ───────────────────────────────────────
class _AppColors {
  static const background = Color(0xFFE8F1FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFF4F8FF);
  static const primary = Color(0xFF268AFF);
  static const primaryDark = Color(0xFF1577EA);
  static const accentIndigo = Color(0xFF3B5399);
  static const accentPurple = Color(0xFF7C3AED);
  static const accentTeal = Color(0xFF0D9488);
  static const accentAmber = Color(0xFFD97706);
  static const accentRose = Color(0xFFE11D48);
  static const accentGreen = Color(0xFF2CC93C);
  static const textPrimary = Color(0xFF1A2340);
  static const textSecondary = Color(0xFF6B7A99);
  static const decorEllipse = Color(0xFFBDD8FF);
}

// ─── Data model for a menu item ───────────────────────────────────────────────
class _AdminItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _AdminItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: Stack(
        children: [
          // Decorative blurred ellipses (BusTrack style)
          _buildDecorEllipse(top: -80, left: -80, size: 240),
          _buildDecorEllipse(top: 300, right: -60, size: 200),
          _buildDecorEllipse(bottom: 120, left: -40, size: 160),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) =>
                          _AdminCard(item: items[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your platform',
                    style: TextStyle(
                      fontSize: 14,
                      color: _AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              // Avatar / profile chip
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          _QuickStatsRow(),
        ],
      ),
    );
  }

  // ── Items ────────────────────────────────────────────────────────────────────
  List<_AdminItem> _buildItems(BuildContext context) => [
    _AdminItem(
      title: 'Users',
      subtitle: 'Manage accounts',
      icon: Icons.people_rounded,
      accentColor: _AppColors.primary,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
    ),
    _AdminItem(
      title: 'Moderators',
      subtitle: 'Review team',
      icon: Icons.admin_panel_settings_rounded,
      accentColor: _AppColors.accentIndigo,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminModeratorsScreen())),
    ),
    _AdminItem(
      title: 'Platform Rules',
      subtitle: 'Policies & terms',
      icon: Icons.gavel_rounded,
      accentColor: _AppColors.accentAmber,
    ),
    _AdminItem(
      title: 'System Settings',
      subtitle: 'Configuration',
      icon: Icons.tune_rounded,
      accentColor: _AppColors.textSecondary,
    ),
    _AdminItem(
      title: 'Role Definitions',
      subtitle: 'Access control',
      icon: Icons.assignment_ind_rounded,
      accentColor: _AppColors.accentPurple,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminRoleScreen())),
    ),
    _AdminItem(
      title: 'Analytics',
      subtitle: 'Live statistics',
      icon: Icons.bar_chart_rounded,
      accentColor: _AppColors.accentTeal,
    ),
    _AdminItem(
      title: 'Dashboard',
      subtitle: 'System overview',
      icon: Icons.dashboard_rounded,
      accentColor: _AppColors.accentRose,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
    ),
    _AdminItem(
      title: 'Reports',
      subtitle: 'Export & logs',
      icon: Icons.receipt_long_rounded,
      accentColor: _AppColors.accentGreen,
    ),
  ];

  // ── Decorative ellipse ───────────────────────────────────────────────────────
  Widget _buildDecorEllipse({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _AppColors.decorEllipse.withOpacity(0.55),
        ),
      ),
    );
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Users', value: '2.4k', color: _AppColors.primary),
          _divider(),
          _Stat(label: 'Active', value: '183', color: _AppColors.accentGreen),
          _divider(),
          _Stat(label: 'Reports', value: '12', color: _AppColors.accentRose),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: _AppColors.decorEllipse,
  );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Admin Card ───────────────────────────────────────────────────────────────
class _AdminCard extends StatefulWidget {
  final _AdminItem item;

  const _AdminCard({required this.item});

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.accentColor;
    final isEnabled = item.onTap != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top-right decorative blob
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.08),
                  ),
                ),
              ),
              // Disabled overlay
              if (!isEnabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon bubble
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: color, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bottom indicator / CTA
                    Row(
                      children: [
                        Container(
                          height: 3,
                          width: isEnabled ? 32 : 16,
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? color
                                : _AppColors.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        if (isEnabled)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_ios_rounded,
                                size: 11, color: color),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
