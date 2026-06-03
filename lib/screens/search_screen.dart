import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = "";
  List<dynamic> _userSearchResults = [];
  List<dynamic> _postSearchResults = [];
  bool _isSearching = false;
  int _searchTab = 0; // 0 for Users, 1 for Posts

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id ?? "";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  style: GoogleFonts.spaceMono(color: Colors.white),
                  onChanged: (val) async {
                    setState(() {
                      _searchQuery = val;
                      _isSearching = true;
                    });
                    if (val.trim().isNotEmpty) {
                      final users = await ApiService.searchUsers(val, currentUserId);
                      final posts = await ApiService.searchPosts(val, currentUserId);
                      if (mounted) {
                        setState(() {
                          _userSearchResults = users;
                          _postSearchResults = posts;
                          _isSearching = false;
                        });
                      }
                    } else {
                      if (mounted) {
                        setState(() {
                          _userSearchResults = [];
                          _postSearchResults = [];
                          _isSearching = false;
                        });
                      }
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "SEARCH_DATABASE...",
                    hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.peach),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _searchTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _searchTab == 0 ? AppTheme.peach : Colors.transparent, width: 2)),
                        ),
                        child: Center(child: Text("USERS", style: GoogleFonts.spaceMono(color: _searchTab == 0 ? AppTheme.peach : Colors.white54, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _searchTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _searchTab == 1 ? AppTheme.peach : Colors.transparent, width: 2)),
                        ),
                        child: Center(child: Text("POSTS", style: GoogleFonts.spaceMono(color: _searchTab == 1 ? AppTheme.peach : Colors.white54, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchQuery.isEmpty 
                ? Center(child: Text('ENTER_QUERY_TO_INITIATE_SEARCH', style: GoogleFonts.spaceMono(color: Colors.white24)))
                : _isSearching
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
                  : _searchTab == 0 
                    ? _buildUserSearchResults()
                    : _buildPostSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResults() {
    if (_userSearchResults.isEmpty) {
      return Center(child: Text('NO_USERS_FOUND', style: GoogleFonts.spaceMono(color: AppTheme.coral)));
    }
    return ListView.builder(
      itemCount: _userSearchResults.length,
      itemBuilder: (context, idx) {
        final user = _userSearchResults[idx];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.peach,
            child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.darkPurple)),
          ),
          title: Text("@${user['name']}", style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("ID: ${user['id'].toString().substring(0, 8)}...", style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.mediumPurple,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_rounded, color: AppTheme.peach),
                      title: Text("VIEW_PROFILE", style: GoogleFonts.spaceMono(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: user['id'])));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_rounded, color: AppTheme.peach),
                      title: Text("INITIATE_TRANSMISSION", style: GoogleFonts.spaceMono(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(otherUserId: user['id'], otherUsername: user['name'])));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostSearchResults() {
    if (_postSearchResults.isEmpty) {
      return Center(child: Text('NO_POSTS_FOUND', style: GoogleFonts.spaceMono(color: AppTheme.coral)));
    }
    return const Center(child: Text("POST_SEARCH_NOT_IMPLEMENTED_YET", style: TextStyle(color: Colors.white24)));
  }
}
