import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/widgets/custom_floating_nav_bar.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:share_plus/share_plus.dart';

// Global key to trigger profile refresh from outside
final GlobalKey<ProfileScreenState> profileKey = GlobalKey<ProfileScreenState>();

class TaggingTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<TextSpan> children = [];
    final RegExp tagRegExp = RegExp(r"(@\w+)");

    text.splitMapJoin(
      tagRegExp,
      onMatch: (Match match) {
        children.add(TextSpan(
          text: match[0],
          style: style?.copyWith(color: const Color(0xFF00FFD1), fontWeight: FontWeight.bold),
        ));
        return "";
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return "";
      },
    );

    return TextSpan(style: style, children: children);
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final feed = await ApiService.getFeed(auth.user?.id);
    if (!mounted) return;
    setState(() {
      _posts = feed;
      _isLoading = false;
    });
  }

  Future<void> _handleLike(String postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showFeedback("LOGIN_REQUIRED_TO_REACT");
      return;
    }

    final success = await ApiService.likePost(authProvider.user!.id, postId);
    if (success) {
      _fetchFeed(); 
    }
  }

  Future<void> _handleSave(String postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showFeedback("LOGIN_REQUIRED_TO_SAVE");
      return;
    }

    final success = await ApiService.savePost(authProvider.user!.id, postId);
    if (success) {
      _fetchFeed(); 
      _showFeedback("TRANSMISSION_STATUS_UPDATED");
    }
  }

  Future<void> _handleShare(String postId, String content, String author) async {
    try {
      await Share.share(
        'Check out this TruthNet transmission from $author: \n\n"$content"',
        subject: 'TruthNet Content',
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await ApiService.sharePost(authProvider.user!.id, postId);
        _fetchFeed();
      }
    } catch (e) {
      debugPrint("DEBUG: SHARE_ERROR: $e");
    }
  }

  Widget _buildRichText(String text, {double fontSize = 13, Color defaultColor = Colors.white}) {
    final List<TextSpan> children = [];
    final RegExp tagRegExp = RegExp(r"(@\w+)");

    text.splitMapJoin(
      tagRegExp,
      onMatch: (Match match) {
        children.add(TextSpan(
          text: match[0],
          style: GoogleFonts.spaceMono(color: const Color(0xFF00FFD1), fontWeight: FontWeight.bold, fontSize: fontSize),
        ));
        return "";
      },
      onNonMatch: (String part) {
        children.add(TextSpan(
          text: part,
          style: GoogleFonts.spaceMono(color: defaultColor, fontSize: fontSize),
        ));
        return "";
      },
    );

    return RichText(
      text: TextSpan(children: children),
    );
  }

  void _showCommentSheet(String postId) async {
    final TaggingTextEditingController _commentController = TaggingTextEditingController();
    List<dynamic> _comments = await ApiService.getComments(postId);
    List<dynamic> _userSearchResults = [];
    String? _replyToId;
    String? _replyToAuthor;
    Map<String, List<dynamic>> _repliesMap = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: const Color(0xFF1A1A2E).withOpacity(0.85),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Text("COMMENTS_STREAM", style: GoogleFonts.righteous(color: const Color(0xFF00FFD1), fontSize: 18)),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: _comments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text("NO_RESPONSES_DETECTED", style: GoogleFonts.spaceMono(color: Colors.white24, fontSize: 12)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final commentId = comment['id'];
                              final bool hasReplies = (comment['replyCount'] ?? 0) > 0;
                              final bool isExpanded = _repliesMap.containsKey(commentId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(comment['author'] ?? "ANON", 
                                          style: GoogleFonts.spaceMono(color: const Color(0xFFFF003C), fontWeight: FontWeight.bold, fontSize: 12)),
                                        const Spacer(),
                                        _buildSmallAction(Icons.favorite_rounded, "${comment['likeCount'] ?? 0}", const Color(0xFFFF003C), () async {
                                          final auth = Provider.of<AuthProvider>(context, listen: false);
                                          if (auth.user != null) {
                                            await ApiService.likeComment(auth.user!.id, commentId);
                                            final updated = await ApiService.getComments(postId);
                                            setModalState(() => _comments = updated);
                                          }
                                        }),
                                        const SizedBox(width: 10),
                                        _buildSmallAction(Icons.reply_rounded, "", Colors.white54, () {
                                          setModalState(() {
                                            _replyToId = commentId;
                                            _replyToAuthor = comment['author'];
                                          });
                                        }),
                                      ],
                                    ),
                                    _buildRichText(comment['content'] ?? "", fontSize: 13),
                                    if (hasReplies || isExpanded)
                                       Padding(
                                         padding: const EdgeInsets.only(left: 20, top: 5),
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             if (hasReplies)
                                               InkWell(
                                                 onTap: () async {
                                                    if (isExpanded) {
                                                      setModalState(() => _repliesMap.remove(commentId));
                                                    } else {
                                                      final replies = await ApiService.getReplies(commentId);
                                                      setModalState(() => _repliesMap[commentId] = replies);
                                                    }
                                                 },
                                                 child: Text(isExpanded ? "HIDE_REPLIES" : "VIEW_${comment['replyCount']}_REPLIES", 
                                                    style: GoogleFonts.spaceMono(color: const Color(0xFF00FFD1).withOpacity(0.5), fontSize: 10, decoration: TextDecoration.underline)),
                                               ),
                                             if (isExpanded)
                                               ...(_repliesMap[commentId] ?? []).map((reply) => Padding(
                                                 padding: const EdgeInsets.only(top: 8),
                                                 child: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Row(
                                                       children: [
                                                         Text(reply['author'] ?? "ANON", style: GoogleFonts.spaceMono(color: const Color(0xFFFF003C), fontSize: 11, fontWeight: FontWeight.bold)),
                                                         const Spacer(),
                                                         _buildSmallAction(Icons.favorite_rounded, "${reply['likeCount'] ?? 0}", const Color(0xFFFF003C), () async {
                                                           final auth = Provider.of<AuthProvider>(context, listen: false);
                                                           if (auth.user != null) {
                                                             await ApiService.likeComment(auth.user!.id, reply['id']);
                                                             final updatedReplies = await ApiService.getReplies(commentId);
                                                             setModalState(() => _repliesMap[commentId] = updatedReplies);
                                                           }
                                                         }),
                                                       ],
                                                     ),
                                                     _buildRichText(reply['content'] ?? "", fontSize: 12, defaultColor: Colors.white70),
                                                   ],
                                                 ),
                                               )).toList(),
                                           ],
                                         ),
                                       ),
                                  ],
                                ),
                              ).animate().fade().slideY(begin: 0.2);
                            },
                          ),
                  ),
                  if (_userSearchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF00FFD1).withOpacity(0.3)),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _userSearchResults.length,
                        itemBuilder: (context, index) {
                          final user = _userSearchResults[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF00FFD1),
                              child: Text(user['name'][0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF0D0D16))),
                            ),
                            title: Text("@${user['name']}", 
                              style: GoogleFonts.spaceMono(color: const Color(0xFF00FFD1), fontSize: 14, fontWeight: FontWeight.bold)),
                            onTap: () {
                              final text = _commentController.text;
                              final atIndex = text.lastIndexOf('@');
                              final newText = text.substring(0, atIndex) + "@${user['name']} ";
                              _commentController.text = newText;
                              _commentController.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
                              setModalState(() => _userSearchResults = []);
                            },
                          );
                        },
                      ),
                    ),
                  const Divider(color: Colors.white10),
                  if (_replyToId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                         color: const Color(0xFF00FFD1).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(5)
                      ),
                      child: Row(
                        children: [
                          Text("REPLYING_TO: @$_replyToAuthor", style: GoogleFonts.spaceMono(color: const Color(0xFFFF003C), fontSize: 10)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                            onPressed: () => setModalState(() => _replyToId = null),
                          )
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _commentController,
                      onChanged: (text) async {
                        final int atIndex = text.lastIndexOf('@');
                        if (atIndex != -1) {
                          final String query = text.substring(atIndex + 1);
                          if (!query.contains(' ')) {
                            final results = await ApiService.searchUsers(query);
                            setModalState(() {
                              _userSearchResults = results;
                            });
                            return;
                          }
                        }
                        if (_userSearchResults.isNotEmpty) {
                          setModalState(() {
                            _userSearchResults = [];
                          });
                        }
                      },
                      style: GoogleFonts.spaceMono(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _replyToId == null ? "ADD_RESPONSE..." : "ADD_REPLY...",
                        hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF00FFD1)),
                          onPressed: () async {
                            if (_commentController.text.trim().isEmpty) return;
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.user != null) {
                              bool success;
                              if (_replyToId == null) {
                                success = await ApiService.addComment(auth.user!.id, postId, _commentController.text.trim());
                              } else {
                                success = await ApiService.replyToComment(auth.user!.id, _replyToId!, _commentController.text.trim());
                              }

                              if (success) {
                                final newComments = await ApiService.getComments(postId);
                                setModalState(() {
                                  _comments = newComments;
                                  _commentController.clear();
                                  _replyToId = null;
                                  _repliesMap.clear(); 
                                });
                                _fetchFeed();
                              }
                            } else {
                              _showFeedback("LOGIN_REQUIRED_TO_COMMENT");
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String postId, String currentContent) {
    final _editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF00FFD1).withOpacity(0.5)),
        ),
        title: Text("EDIT_TRANSMISSION", style: GoogleFonts.righteous(color: const Color(0xFF00FFD1))),
        content: TextField(
          controller: _editController,
          maxLines: null,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: "UPDATE_DATA...",
            hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00FFD1))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFF00FFD1),
               foregroundColor: const Color(0xFF0D0D16),
            ),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await ApiService.updatePost(postId, auth.user!.id, _editController.text.trim());
              Navigator.pop(context);
              if (success) {
                _fetchFeed();
                _showFeedback("TRANSMISSION_UPDATED");
              } else {
                _showFeedback("EDIT_FAILED_THE_POST_PASSED_24_HOURS");
              }
            },
            child: Text("UPDATE", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(String postId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFFF003C).withOpacity(0.5)),
        ),
        title: Text("DELETE_CONFIRMATION", style: GoogleFonts.righteous(color: const Color(0xFFFF003C))),
        content: Text("ERASE_THIS_TRANSMISSION_PERMANENTLY?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("NO", style: GoogleFonts.spaceMono(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF003C), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: Text("YES_ERASE", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deletePost(postId, auth.user!.id);
      if (success) {
        _fetchFeed();
        if (_selectedIndex == 3) profileKey.currentState?.fetchProfile();
        _showFeedback("TRANSMISSION_ERASED");
      }
    }
  }

  Widget _buildSmallAction(IconData icon, String count, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
              if (count.isNotEmpty && count != "0") ...[
                const SizedBox(width: 4),
                Text(count, style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono(color: const Color(0xFF0D0D16), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00FFD1),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final List<Map<String, dynamic>> navItems = _getNavItems(role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true, // Needed for floating nav bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color(0xFF0D0D16).withOpacity(0.5)),
          ),
        ),
        title: Hero(
          tag: 'logo',
          child: Text(
            'TruthNet',
            style: GoogleFonts.righteous(
              color: const Color(0xFF00FFD1),
              fontSize: 32,
              letterSpacing: -1,
              shadows: [Shadow(color: const Color(0xFF00FFD1).withOpacity(0.5), blurRadius: 10)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFE600)), // Neon Yellow
            onPressed: () {
              _fetchFeed();
              if (_selectedIndex == 3) profileKey.currentState?.fetchProfile();
            },
          ),
          IconButton(
            icon: Icon(role == UserRole.guest ? Icons.login_rounded : Icons.logout_rounded, color: const Color(0xFFFF003C)), // Magenta
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: DynamicBackground(
        child: _buildBody(_selectedIndex, role),
      ),
      bottomNavigationBar: CustomFloatingNavBar(
        currentIndex: _selectedIndex,
        items: navItems,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: role == UserRole.member || role == UserRole.admin
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0), // Above the custom nav bar
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/post');
                  if (result == true) {
                    _fetchFeed();
                    if (_selectedIndex == 3) profileKey.currentState?.fetchProfile();
                  }
                },
                child: const Icon(Icons.add_rounded, color: Color(0xFF0D0D16)),
                backgroundColor: const Color(0xFF00FFD1),
                elevation: 8,
              ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
            )
          : null,
    );
  }

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

  Widget _buildBody(int index, UserRole role) {
    switch (index) {
      case 0:
        return _isLoading ? _buildShimmerFeed() : _buildFeed();
      case 1:
        return Center(child: Text('SEARCH_DATABASE...', style: GoogleFonts.spaceMono(color: const Color(0xFFFF003C))));
      case 3:
        return ProfileScreen(key: profileKey);
      default:
        return _isLoading ? _buildShimmerFeed() : _buildFeed();
    }
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 120, bottom: 100),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 14, color: Colors.white),
                        const SizedBox(height: 5),
                        Container(width: 80, height: 10, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 5),
                Container(width: MediaQuery.of(context).size.width * 0.7, height: 14, color: Colors.white),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => Container(width: 40, height: 20, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeed() {
    if (_posts.isEmpty) {
      return Center(child: Text("NO_TRANSMISSIONS_FOUND", style: GoogleFonts.spaceMono(color: Colors.white24)));
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 120, bottom: 120), // Extra bottom padding for nav bar
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final postId = post['id'];
        final mediaUrl = post['mediaUrl'];
        final author = post['author'] ?? "UNKNOWN_SOURCE";
        final authorId = post['authorId'];
        final content = post['content'] ?? "";
        final location = post['location'];
        final likeCount = post['likeCount'] ?? 0;
        final commentCount = post['commentCount'] ?? 0;
        final shareCount = post['shareCount'] ?? 0;
        final isSaved = post['isSaved'] ?? false;
        final isLiked = post['isLiked'] ?? false;

        final bool isOwner = auth.user?.id == authorId;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FFD1).withOpacity(0.1)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FFD1), width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF0D0D16),
                          child: Text(author[0].toUpperCase(), style: GoogleFonts.spaceMono(color: const Color(0xFF00FFD1), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(author, style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            if (location != null)
                              Text("📍 $location", style: GoogleFonts.spaceMono(color: const Color(0xFFFFE600).withOpacity(0.8), fontSize: 9)),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white30),
                          color: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.white10)),
                          onSelected: (value) {
                            if (value == 'edit') _showEditDialog(postId, content);
                            if (value == 'delete') _handleDelete(postId);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text("EDIT_DATA", style: GoogleFonts.spaceMono(color: Colors.white)),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text("ERASE_NODE", style: GoogleFonts.spaceMono(color: const Color(0xFFFF003C))),
                            ),
                          ],
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white30),
                          onPressed: () => _showFeedback("REPORTING_PROTOCOL_INITIATED..."),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _buildRichText(content, fontSize: 13),
                  ),
                  if (mediaUrl != null)
                    Container(
                      height: 220,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D16).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          "${ApiService.baseUrl.replaceFirst('/api', '')}$mediaUrl",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, color: Colors.white10);
                          },
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        Icons.favorite_rounded, 
                        '$likeCount', 
                        isLiked ? const Color(0xFFFF003C) : Colors.white30, 
                        () => _handleLike(postId)
                      ),
                      _buildActionButton(Icons.comment_rounded, '$commentCount', const Color(0xFF00FFD1), () => _showCommentSheet(postId)),
                      _buildActionButton(Icons.share_rounded, '$shareCount', Colors.white30, () => _handleShare(postId, content, author)),
                      _buildActionButton(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                        '', 
                        isSaved ? const Color(0xFFFFE600) : Colors.white30, 
                        () => _handleSave(postId)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fade(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1); // Staggered Animation
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              if (label.isNotEmpty && label != "0") ...[
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
