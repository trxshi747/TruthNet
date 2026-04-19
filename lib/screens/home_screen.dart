import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:share_plus/share_plus.dart';

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
      _fetchFeed(); // Refresh to update bookmark state
      _showFeedback("TRANSMISSION_STATUS_UPDATED");
    }
  }

  Future<void> _handleShare(String postId, String content, String author) async {
    debugPrint("DEBUG: TRIGGERING_SHARE_SHEET...");
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

  void _showCommentSheet(String postId) async {
    final TextEditingController _commentController = TextEditingController();
    List<dynamic> _comments = await ApiService.getComments(postId);
    String? _replyToId;
    String? _replyToAuthor;
    Map<String, List<dynamic>> _repliesMap = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF312C51),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("COMMENTS", style: GoogleFonts.righteous(color: const Color(0xFFF0C38E), fontSize: 18)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
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
                                      style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontWeight: FontWeight.bold, fontSize: 12)),
                                    const Spacer(),
                                    _buildSmallAction(Icons.favorite_rounded, "${comment['likeCount'] ?? 0}", () async {
                                      final auth = Provider.of<AuthProvider>(context, listen: false);
                                      if (auth.user != null) {
                                        await ApiService.likeComment(auth.user!.id, commentId);
                                        final updated = await ApiService.getComments(postId);
                                        setModalState(() => _comments = updated);
                                      }
                                    }),
                                    const SizedBox(width: 10),
                                    _buildSmallAction(Icons.reply_rounded, "", () {
                                      setModalState(() {
                                        _replyToId = commentId;
                                        _replyToAuthor = comment['author'];
                                      });
                                    }),
                                  ],
                                ),
                                Text(comment['content'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13)),
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
                                                style: GoogleFonts.spaceMono(color: const Color(0xFFF0C38E).withOpacity(0.5), fontSize: 10, decoration: TextDecoration.underline)),
                                           ),
                                         if (isExpanded)
                                           ...(_repliesMap[commentId] ?? []).map((reply) => Padding(
                                             padding: const EdgeInsets.only(top: 8),
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Row(
                                                   children: [
                                                     Text(reply['author'] ?? "ANON", style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontSize: 11, fontWeight: FontWeight.bold)),
                                                     const Spacer(),
                                                     _buildSmallAction(Icons.favorite_rounded, "${reply['likeCount'] ?? 0}", () async {
                                                       final auth = Provider.of<AuthProvider>(context, listen: false);
                                                       if (auth.user != null) {
                                                         await ApiService.likeComment(auth.user!.id, reply['id']);
                                                         final updatedReplies = await ApiService.getReplies(commentId);
                                                         setModalState(() => _repliesMap[commentId] = updatedReplies);
                                                       }
                                                     }),
                                                   ],
                                                 ),
                                                 Text(reply['content'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
                                               ],
                                             ),
                                           )).toList(),
                                       ],
                                     ),
                                   ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(color: Colors.white10),
              if (_replyToId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.white.withOpacity(0.05),
                  child: Row(
                    children: [
                      Text("REPLYING_TO: @$_replyToAuthor", style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontSize: 10)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                        onPressed: () => setModalState(() => _replyToId = null),
                      )
                    ],
                  ),
                ),
              TextField(
                controller: _commentController,
                style: GoogleFonts.spaceMono(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _replyToId == null ? "ADD_COMMENT..." : "ADD_REPLY...",
                  hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFFF0C38E)),
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
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
        backgroundColor: const Color(0xFF312C51),
        title: Text("EDIT_TRANSMISSION", style: GoogleFonts.righteous(color: const Color(0xFFF0C38E))),
        content: TextField(
          controller: _editController,
          maxLines: null,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: "UPDATE_DATA...",
            hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF0C38E)),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await ApiService.updatePost(postId, auth.user!.id, _editController.text.trim());
              Navigator.pop(context);
              if (success) {
                _fetchFeed();
                _showFeedback("TRANSMISSION_UPDATED");
              } else {
                _showFeedback("EDIT_FAILED_WINDOW_EXPIRED");
              }
            },
            child: Text("UPDATE", style: GoogleFonts.spaceMono(color: const Color(0xFF312C51))),
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
        backgroundColor: const Color(0xFF312C51),
        title: Text("DELETE_CONFIRMATION", style: GoogleFonts.righteous(color: Colors.redAccent)),
        content: Text("ERASE_THIS_TRANSMISSION_PERMANENTLY?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("NO", style: GoogleFonts.spaceMono(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("YES_ERASE", style: GoogleFonts.spaceMono(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deletePost(postId, auth.user!.id);
      if (success) {
        _fetchFeed();
        _showFeedback("TRANSMISSION_ERASED");
      }
    }
  }

  Widget _buildSmallAction(IconData icon, String count, VoidCallback onTap) {
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
              Icon(icon, size: 14, color: const Color(0xFFF0C38E).withOpacity(0.7)),
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
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: const Color(0xFF48426D),
        duration: const Duration(milliseconds: 1500),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Hero(
          tag: 'logo',
          child: Text(
            'TruthNet',
            style: GoogleFonts.righteous(
              color: const Color(0xFFF0C38E),
              fontSize: 32,
              letterSpacing: -1,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF1AA9B)),
            onPressed: _fetchFeed,
          ),
          IconButton(
            icon: Icon(role == UserRole.guest ? Icons.login_rounded : Icons.logout_rounded, color: const Color(0xFFF1AA9B)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF312C51).withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFF0C38E),
          unselectedItemColor: const Color(0xFFF1AA9B).withOpacity(0.5),
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
      floatingActionButton: role == UserRole.member || role == UserRole.admin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/post');
                if (result == true) _fetchFeed();
              },
              child: const Icon(Icons.add_rounded, color: Color(0xFF312C51)),
              backgroundColor: const Color(0xFFF0C38E),
              elevation: 8,
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
      items.add({'icon': Icons.chat_bubble_rounded, 'label': 'Messages'});
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
        return _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF0C38E)))
            : _buildFeed();
      case 1:
        return Center(child: Text('SEARCH_DATABASE...', style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B))));
      case 3:
        return Center(child: Text('PROFILE_LOCKED', style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B))));
      default:
        return _isLoading ? const Center(child: CircularProgressIndicator()) : _buildFeed();
    }
  }

  Widget _buildFeed() {
    if (_posts.isEmpty) {
      return Center(child: Text("NO_TRANSMISSIONS_FOUND", style: GoogleFonts.spaceMono(color: Colors.white24)));
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 120, bottom: 20),
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF48426D).withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF1AA9B),
                    child: Text(author[0].toUpperCase(), style: GoogleFonts.spaceMono(color: const Color(0xFF312C51), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        if (location != null)
                          Text("📍 $location", style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B).withOpacity(0.8), fontSize: 9)),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white30),
                      color: const Color(0xFF312C51),
                      onSelected: (value) {
                        if (value == 'edit') _showEditDialog(postId, content);
                        if (value == 'delete') _handleDelete(postId);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text("EDIT_POST", style: GoogleFonts.spaceMono(color: Colors.white)),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text("ERASE_POST", style: GoogleFonts.spaceMono(color: Colors.redAccent)),
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
                child: Text(
                  content,
                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ),
              if (mediaUrl != null)
                Container(
                  height: 220,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312C51).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      "http://10.0.2.2:3000$mediaUrl",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white10),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    Icons.favorite_rounded, 
                    '$likeCount', 
                    isLiked ? Colors.redAccent : const Color(0xFFF1AA9B), 
                    () => _handleLike(postId)
                  ),
                  _buildActionButton(Icons.comment_rounded, '$commentCount', const Color(0xFFF0C38E), () => _showCommentSheet(postId)),
                  _buildActionButton(Icons.share_rounded, '$shareCount', const Color(0xFF312C51), () => _handleShare(postId, content, author)),
                  _buildActionButton(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                    '', 
                    isSaved ? const Color(0xFFF0C38E) : Colors.white10, 
                    () => _handleSave(postId)
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: (color == const Color(0xFF312C51) || color == Colors.white10) ? Colors.white70 : color),
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
