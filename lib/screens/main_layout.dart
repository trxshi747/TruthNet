import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/widgets/custom_floating_nav_bar.dart';
import 'package:model2/screens/home_screen.dart';
import 'package:model2/screens/message_screen.dart';
import 'package:model2/screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> _getNavItems(UserRole role) {
    List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.search_rounded, 'label': 'Search'},
    ];
    if (role != UserRole.guest) {
      items.add({'icon': Icons.chat_bubble_rounded, 'label': 'Comms'});
      items.add({'icon': Icons.person_rounded, 'label': 'Profile'});
    }
    if (role == UserRole.moderator || role == UserRole.admin) {
      items.add({'icon': Icons.security_rounded, 'label': 'Mod'});
    }
    if (role == UserRole.admin) {
      items.add({'icon': Icons.dashboard_rounded, 'label': 'Admin'});
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final navItems = _getNavItems(role);
    final theme = Theme.of(context);

    final List<Widget> screens = [
      HomeScreen(),
      Center(child: Text('Searching...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary))),
    ];
    
    if (role != UserRole.guest) {
      screens.add(MessageScreen());
      screens.add(ProfileScreen(key: profileKey));
    }
    if (role == UserRole.moderator || role == UserRole.admin) {
      screens.add(const Center(child: Text('Moderator')));
    }
    if (role == UserRole.admin) {
      screens.add(const Center(child: Text('Admin')));
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Layer 1: Dynamic Background
          const DynamicBackground(child: null,),
          
          // Layer 2: Screens
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          
          // Layer 3: Floating Nav Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomFloatingNavBar(
              currentIndex: _currentIndex,
              items: navItems,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
