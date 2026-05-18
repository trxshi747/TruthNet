import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/services/mock_service.dart';
import 'package:model2/widgets/dynamic_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _stats = MockService.getDashboardStats();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détecter la taille de l'écran pour adapter l'affichage
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    // Nombre de colonnes selon la taille d'écran
    int crossAxisCount = 2;
    if (isMobile) crossAxisCount = 1;
    if (isTablet) crossAxisCount = 2;
    if (isDesktop) crossAxisCount = 4;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bienvenue
                    _buildWelcomeHeader(),

                    const SizedBox(height: 24),

                    // Cartes de statistiques
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFFF0C38E)),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 1.8 : 1.5,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final cards = [
                            _StatCard(
                              title: 'TOTAL_USERS',
                              value: _stats['totalUsers']?.toString() ?? '0',
                              icon: Icons.people,
                              color: Colors.blue,
                              change: '+12%',
                              isPositive: true,
                            ),
                            _StatCard(
                              title: 'ACTIVE_USERS',
                              value: _stats['activeUsers']?.toString() ?? '0',
                              icon: Icons.person,
                              color: Colors.green,
                              change: '+5%',
                              isPositive: true,
                            ),
                            _StatCard(
                              title: 'TOTAL_POSTS',
                              value: _stats['totalPosts']?.toString() ?? '0',
                              icon: Icons.post_add,
                              color: Colors.purple,
                              change: '+8%',
                              isPositive: true,
                            ),
                            _StatCard(
                              title: 'REPORTS',
                              value: _stats['pendingReports']?.toString() ?? '0',
                              icon: Icons.flag,
                              color: Colors.orange,
                              change: '-3%',
                              isPositive: false,
                            ),
                          ];
                          return cards[index];
                        },
                      ),

                    const SizedBox(height: 30),

                    // Section récente
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME_BACK_ADMIN',
          style: GoogleFonts.righteous(
            fontSize: 20,
            color: const Color(0xFFF0C38E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here is what\'s happening on your platform today.',
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT_ACTIVITY',
          style: GoogleFonts.righteous(
            fontSize: 16,
            color: const Color(0xFFF0C38E),
          ),
        ),
        const SizedBox(height: 15),

        // Utiliser ListView.builder avec shrinkWrap
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF48426D).withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white24,
              height: 1,
            ),
            itemBuilder: (context, index) {
              return const ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                title: Text(
                  'User posted a new content',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                subtitle: Text(
                  '2 minutes ago',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white38, size: 18),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget des cartes statistiques (inchangé mais déplacé hors du build)
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.righteous(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}