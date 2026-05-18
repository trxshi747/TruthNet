import 'package:flutter/material.dart';

import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_moderator_screen.dart';
import 'admin/admin_role_screen.dart';
import 'admin/admin_users_screen.dart';

// ─── Material 3 Custom Color Scheme ────────────────────────────────────────
//
//  Inspired by BeReal's raw honesty and Signal's trustworthy restraint.
//  Warm off-white surface, deep charcoal text, a single honest accent.
//
final ColorScheme _adminColorScheme = ColorScheme(
  brightness: Brightness.light,

  // Primary: deep slate-blue — authority without aggression
  primary: const Color(0xFF1E2D40),
  onPrimary: const Color(0xFFF7F5F2),
  primaryContainer: const Color(0xFFD8E4F0),
  onPrimaryContainer: const Color(0xFF0D1B2A),

  // Secondary: warm stone — human, tactile
  secondary: const Color(0xFF5C5552),
  onSecondary: const Color(0xFFF7F5F2),
  secondaryContainer: const Color(0xFFEDE8E4),
  onSecondaryContainer: const Color(0xFF2E2A28),

  // Tertiary: muted sage — calm, ethical
  tertiary: const Color(0xFF4A6358),
  onTertiary: const Color(0xFFF7F5F2),
  tertiaryContainer: const Color(0xFFCCDDD6),
  onTertiaryContainer: const Color(0xFF1A2E27),

  // Error
  error: const Color(0xFFB3261E),
  onError: const Color(0xFFF7F5F2),
  errorContainer: const Color(0xFFF9DEDC),
  onErrorContainer: const Color(0xFF410E0B),

  // Surface: warm off-white — paper-like, honest
  surface: const Color(0xFFF7F5F2),
  onSurface: const Color(0xFF1A1917),
  surfaceContainerHighest: const Color(0xFFEDE8E4),
  onSurfaceVariant: const Color(0xFF4A4745),

  // Outline
  outline: const Color(0xFFCAC5C0),
  outlineVariant: const Color(0xFFE0DAD6),

  // Misc
  shadow: const Color(0xFF000000),
  scrim: const Color(0xFF000000),
  inverseSurface: const Color(0xFF302E2C),
  onInverseSurface: const Color(0xFFF3EEE9),
  inversePrimary: const Color(0xFFADC8E8),
);

// ─── Destination Model ──────────────────────────────────────────────────────

class _AdminDestination {
  const _AdminDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget? route;
}

// ─── Admin Screen ───────────────────────────────────────────────────────────

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static const List<_AdminDestination> _destinations = [
    _AdminDestination(
      title: 'Users',
      subtitle: 'Accounts & access',
      icon: Icons.people_outline_rounded,
      accentColor: Color(0xFF1E2D40),
      route: AdminUsersScreen(),
    ),
    _AdminDestination(
      title: 'Moderators',
      subtitle: 'Trust & safety team',
      icon: Icons.shield_outlined,
      accentColor: Color(0xFF4A6358),
      route: AdminModeratorsScreen(),
    ),
    _AdminDestination(
      title: 'Roles',
      subtitle: 'Permissions & scope',
      icon: Icons.badge_outlined,
      accentColor: Color(0xFF5C5552),
      route: AdminRoleScreen(),
    ),
    _AdminDestination(
      title: 'Dashboard',
      subtitle: 'Live system health',
      icon: Icons.space_dashboard_outlined,
      accentColor: Color(0xFF1E2D40),
      route: AdminDashboardScreen(),
    ),
    _AdminDestination(
      title: 'Rules',
      subtitle: 'Platform guidelines',
      icon: Icons.gavel_rounded,
      accentColor: Color(0xFF7A5C44),
    ),
    _AdminDestination(
      title: 'Settings',
      subtitle: 'System configuration',
      icon: Icons.tune_rounded,
      accentColor: Color(0xFF5C5552),
    ),
    _AdminDestination(
      title: 'Analytics',
      subtitle: 'Usage & insights',
      icon: Icons.bar_chart_rounded,
      accentColor: Color(0xFF4A6358),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: _adminColorScheme,
        fontFamily: 'Söhne', // falls back gracefully
      ),
      child: Builder(builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: cs.surface,
          body: CustomScrollView(
            slivers: [
              // ── Large App Bar ─────────────────────────────────────────
              SliverAppBar.large(
                backgroundColor: cs.surface,
                foregroundColor: cs.onSurface,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                title: const Text('Admin'),
                titleTextStyle: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    tooltip: 'Notifications',
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Status Banner ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: _StatusBanner(colorScheme: cs),
                ),
              ),

              // ── Section label ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Management',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              // ── Grid ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _destinations.length,
                  itemBuilder: (context, index) {
                    return _AdminCard(
                      destination: _destinations[index],
                      index: index,
                    );
                  },
                ),
              ),

              // ── Bottom padding ────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Status Banner ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF4A6358),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All systems operational',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          Text(
            'View status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Card ─────────────────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.destination, required this.index});

  final _AdminDestination destination;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasRoute = destination.route != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasRoute
            ? () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination.route!),
        )
            : null,
        splashColor: destination.accentColor.withOpacity(0.08),
        highlightColor: destination.accentColor.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: destination.accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  destination.icon,
                  size: 22,
                  color: destination.accentColor,
                ),
              ),
              const Spacer(),

              // Title
              Text(
                destination.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle
              Text(
                destination.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Disabled hint
              if (!hasRoute) ...[
                const SizedBox(height: 8),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}