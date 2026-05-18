import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';

// Import des écrans
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_moderator_screen.dart';
import 'admin_role_screen.dart';
import 'admin_rules_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_analytics_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Liste des écrans
  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminModeratorsScreen(),
    const AdminRoleScreen(),
    const AdminRulesScreen(),
    const AdminSettingsScreen(),
    const AdminAnalyticsScreen(),
  ];

  // Liste des titres
  final List<String> _titles = [
    'DASHBOARD',
    'USER_MANAGEMENT',
    'MODERATOR_TEAM',
    'ROLE_DEFINITIONS',
    'PLATFORM_RULES',
    'SYSTEM_SETTINGS',
    'ANALYTICS',
  ];

  // Liste des icônes
  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.people,
    Icons.admin_panel_settings,
    Icons.assignment_ind,
    Icons.gavel,
    Icons.settings,
    Icons.analytics,
  ];

  // Liste des couleurs
  final List<Color> _colors = [
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.brown,
    Colors.grey,
    Colors.orange,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Fermer le drawer sur mobile (optionnel)
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Vérification des droits admin
    if (auth.role != UserRole.admin) {
      return Scaffold(
        body: DynamicBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                Text(
                  'ACCESS_DENIED',
                  style: GoogleFonts.righteous(
                    fontSize: 24,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ADMIN_PRIVILEGES_REQUIRED',
                  style: GoogleFonts.spaceMono(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0C38E),
                  ),
                  child: Text(
                    'RETURN',
                    style: GoogleFonts.spaceMono(color: const Color(0xFF312C51)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.righteous(
            fontSize: 18,
            color: const Color(0xFFF0C38E),
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Badge de notification admin
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white70),
                onPressed: () {
                  // TODO: Afficher les notifications admin
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: DynamicBackground(
        child: _screens[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF312C51),
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // En-tête du drawer
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF48426D),
                  const Color(0xFF312C51),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0C38E), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF48426D),
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFFF0C38E)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'TRUTHNET',
                  style: GoogleFonts.righteous(
                    fontSize: 18,
                    color: const Color(0xFFF0C38E),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMINISTRATOR',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Navigation items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _titles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return _buildDrawerItem(
                  title: _titles[index],
                  icon: _icons[index],
                  color: _colors[index],
                  isSelected: isSelected,
                  onTap: () => _onItemTapped(index),
                );
              },
            ),
          ),

          // Footer
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Text(
                  'LOGOUT',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? color : Colors.white54,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            color: isSelected ? color : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        )
            : null,
        onTap: onTap,
      ),
    );
  }
}