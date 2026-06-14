import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/providers/notification_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/post_screen.dart';
import 'package:model2/screens/notifications_screen.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/message_screen.dart';
import 'package:model2/screens/chat_screen.dart';
import 'package:share_plus/share_plus.dart';

import 'package:model2/widgets/video_player_widget.dart';

import 'package:model2/core/theme/app_theme.dart';

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
          style: style?.copyWith(color: AppTheme.peach, fontWeight: FontWeight.bold),
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

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0;
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);
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

    // Optimistic UI update
    setState(() {
      final index = _posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        final post = _posts[index];
        final bool currentlyLiked = post['isLiked'] ?? false;
        post['isLiked'] = !currentlyLiked;
        post['likeCount'] = currentlyLiked ? (post['likeCount'] ?? 1) - 1 : (post['likeCount'] ?? 0) + 1;
      }
    });

    final success = await ApiService.likePost(authProvider.user!.id, postId);
    if (success) {
      _fetchFeed(showLoading: false); 
    } else {
      _fetchFeed(); // Revert/Refresh properly on failure
    }
  }

  Future<void> _handleSave(String postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showFeedback("LOGIN_REQUIRED_TO_SAVE");
      return;
    }

    // Optimistic UI update
    setState(() {
      void updatePostStatus(dynamic post) {
        post['isSaved'] = !(post['isSaved'] ?? false);
      }
      
      final index = _posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) updatePostStatus(_posts[index]);

      final searchIndex = _postSearchResults.indexWhere((p) => p['id'] == postId);
      if (searchIndex != -1) updatePostStatus(_postSearchResults[searchIndex]);
    });

    final success = await ApiService.savePost(authProvider.user!.id, postId);
    if (success) {
      _showFeedback("TRANSMISSION_STATUS_UPDATED");
    } else {
      _fetchFeed();
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
        // Optimistic UI update
        setState(() {
          void updatePostStatus(dynamic post) {
            post['shareCount'] = (post['shareCount'] ?? 0) + 1;
          }

          final index = _posts.indexWhere((p) => p['id'] == postId);
          if (index != -1) updatePostStatus(_posts[index]);

          final searchIndex = _postSearchResults.indexWhere((p) => p['id'] == postId);
          if (searchIndex != -1) updatePostStatus(_postSearchResults[searchIndex]);
        });

        await ApiService.sharePost(authProvider.user!.id, postId);
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
          style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold, fontSize: fontSize),
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
              color: AppTheme.mediumPurple.withOpacity(0.85),
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
                  Text("COMMENTS_STREAM", style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 18)),
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
                              final authorId = comment['authorId'];
                              final bool hasReplies = (comment['replyCount'] ?? 0) > 0;
                              final bool isExpanded = _repliesMap.containsKey(commentId);
                              
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final bool isOwner = auth.user?.id == authorId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(context); // Close bottom sheet
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: authorId)));
                                          },
                                          child: Text("@${comment['author'] ?? "ANON"}", 
                                            style: GoogleFonts.spaceMono(color: AppTheme.coral, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const Spacer(),
                                        _buildSmallAction(Icons.favorite_rounded, "${comment['likeCount'] ?? 0}", AppTheme.coral, () async {
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
                                            final tag = "@$_replyToAuthor ";
                                            if (!_commentController.text.startsWith(tag)) {
                                              _commentController.text = tag + _commentController.text;
                                              _commentController.selection = TextSelection.fromPosition(TextPosition(offset: _commentController.text.length));
                                            }
                                          });
                                        }),
                                        const SizedBox(width: 5),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, size: 14, color: Colors.white24),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 80),
                                          color: AppTheme.mediumPurple,
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showEditCommentDialog(commentId, comment['content'], () async {
                                                final updated = await ApiService.getComments(postId);
                                                setModalState(() => _comments = updated);
                                              });
                                            } else if (val == 'delete') {
                                              _handleDeleteComment(commentId, () async {
                                                final updated = await ApiService.getComments(postId);
                                                setModalState(() => _comments = updated);
                                                _fetchFeed();
                                              });
                                            } else if (val == 'report') {
                                              _showReportDialog(commentId, 'Comment');
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (isOwner) PopupMenuItem(value: 'edit', child: Text("EDIT", style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white))),
                                            if (isOwner) PopupMenuItem(value: 'delete', child: Text("DELETE", style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.coral))),
                                            if (!isOwner) PopupMenuItem(value: 'report', child: Text("REPORT", style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.coral))),
                                          ],
                                        ),
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
                                                    style: GoogleFonts.spaceMono(color: AppTheme.peach.withOpacity(0.5), fontSize: 10, decoration: TextDecoration.underline)),
                                               ),
                                             if (isExpanded)
                                               ...(_repliesMap[commentId] ?? []).map((reply) {
                                                 final bool isReplyOwner = auth.user?.id == reply['authorId'];
                                                 return Padding(
                                                 padding: const EdgeInsets.only(top: 8),
                                                 child: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Row(
                                                       children: [
                                                         InkWell(
                                                           onTap: () {
                                                             Navigator.pop(context); // Close bottom sheet
                                                             Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: reply['authorId'])));
                                                           },
                                                           child: Text("@${reply['author'] ?? "ANON"}", style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 11, fontWeight: FontWeight.bold)),
                                                         ),
                                                         const Spacer(),
                                                         _buildSmallAction(Icons.favorite_rounded, "${reply['likeCount'] ?? 0}", AppTheme.coral, () async {
                                                           if (auth.user != null) {
                                                             await ApiService.likeComment(auth.user!.id, reply['id']);
                                                             final updatedReplies = await ApiService.getReplies(commentId);
                                                             setModalState(() => _repliesMap[commentId] = updatedReplies);
                                                           }
                                                         }),
                                                         const SizedBox(width: 10),
                                                         _buildSmallAction(Icons.reply_rounded, "", Colors.white54, () {
                                                           setModalState(() {
                                                             _replyToId = commentId; // Targets the top-level comment
                                                             _replyToAuthor = reply['author'];
                                                             final tag = "@$_replyToAuthor ";
                                                             if (!_commentController.text.startsWith(tag)) {
                                                               _commentController.text = tag + _commentController.text;
                                                               _commentController.selection = TextSelection.fromPosition(TextPosition(offset: _commentController.text.length));
                                                             }
                                                           });
                                                         }),
                                                         const SizedBox(width: 5),
                                                         PopupMenuButton<String>(
                                                             icon: const Icon(Icons.more_vert_rounded, size: 12, color: Colors.white24),
                                                             padding: EdgeInsets.zero,
                                                             constraints: const BoxConstraints(minWidth: 80),
                                                             color: AppTheme.mediumPurple,
                                                             onSelected: (val) {
                                                               if (val == 'edit') {
                                                                 _showEditCommentDialog(reply['id'], reply['content'], () async {
                                                                   final updatedReplies = await ApiService.getReplies(commentId);
                                                                   setModalState(() => _repliesMap[commentId] = updatedReplies);
                                                                 });
                                                               } else if (val == 'delete') {
                                                                 _handleDeleteComment(reply['id'], () async {
                                                                   final updatedReplies = await ApiService.getReplies(commentId);
                                                                   setModalState(() => _repliesMap[commentId] = updatedReplies);
                                                                   final updatedComments = await ApiService.getComments(postId);
                                                                   setModalState(() => _comments = updatedComments);
                                                                 });
                                                               } else if (val == 'report') {
                                                                 _showReportDialog(reply['id'], 'Comment');
                                                               }
                                                             },
                                                             itemBuilder: (context) => [
                                                               if (isReplyOwner) PopupMenuItem(value: 'edit', child: Text("EDIT", style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white))),
                                                               if (isReplyOwner) PopupMenuItem(value: 'delete', child: Text("DELETE", style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.coral))),
                                                               if (!isReplyOwner) PopupMenuItem(value: 'report', child: Text("REPORT", style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.coral))),
                                                             ],
                                                           ),
                                                       ],
                                                     ),
                                                     _buildRichText(reply['content'] ?? "", fontSize: 12, defaultColor: Colors.white70),
                                                   ],
                                                 ),
                                               );}).toList(),
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
                        color: AppTheme.mediumPurple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppTheme.peach.withOpacity(0.3)),
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
                              backgroundColor: AppTheme.peach,
                              child: Text(user['name'][0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.darkPurple)),
                            ),
                            title: Text("@${user['name']}", 
                              style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 14, fontWeight: FontWeight.bold)),
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
                         color: AppTheme.peach.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(5)
                      ),
                      child: Row(
                        children: [
                          Text("REPLYING_TO: @$_replyToAuthor", style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 10)),
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
                          icon: const Icon(Icons.send_rounded, color: AppTheme.peach),
                          onPressed: () async {
                            if (_commentController.text.trim().isEmpty) return;
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.user != null) {
                              Map<String, dynamic> result;
                              if (_replyToId == null) {
                                result = await ApiService.addComment(auth.user!.id, postId, _commentController.text.trim());
                              } else {
                                result = await ApiService.replyToComment(auth.user!.id, _replyToId!, _commentController.text.trim());
                              }

                              if (result['success'] == true) {
                                final newComments = await ApiService.getComments(postId);
                                setModalState(() {
                                  _comments = newComments;
                                  _commentController.clear();
                                  _replyToId = null;
                                  _repliesMap.clear();
                                });
                                _fetchFeed(showLoading: false);
                              } else if (result['message'] == 'CONTENT_TOO_TOXIC') {
                                  _showToxicityAlert(result['detail'] ?? "Your response is too toxic to be published.");
                              } else {
                                  _showFeedback(result['message'] ?? "COMMENT_FAILED");
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

  void _showEditCommentDialog(String commentId, String currentContent, VoidCallback onUpdated) {
    final _editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.peach.withOpacity(0.5)),
        ),
        title: Text("EDIT_RESPONSE", style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: TextField(
          controller: _editController,
          maxLines: null,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: "UPDATE_RESPONSE...",
            hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.peach,
               foregroundColor: AppTheme.darkPurple,
            ),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await ApiService.updateComment(commentId, auth.user!.id, _editController.text.trim());
              Navigator.pop(context);
              if (success) {
                onUpdated();
                _showFeedback("RESPONSE_UPDATED");
              } else {
                _showFeedback("EDIT_FAILED_UNAUTHORIZED");
              }
            },
            child: Text("UPDATE", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteComment(String commentId, VoidCallback onDeleted) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.coral.withOpacity(0.5)),
        ),
        title: Text("DELETE_CONFIRMATION", style: GoogleFonts.righteous(color: AppTheme.coral)),
        content: Text("ERASE_THIS_RESPONSE_PERMANENTLY?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("NO", style: GoogleFonts.spaceMono(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: Text("YES_ERASE", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteComment(commentId, auth.user!.id);
      if (success) {
        onDeleted();
        _showFeedback("RESPONSE_ERASED");
      } else {
        _showFeedback("ERASE_FAILED_UNAUTHORIZED");
      }
    }
  }

  void _showReportDialog(String targetId, String targetType) {
    String selectedReason = 'Spam';
    final List<String> reasons = ['Spam', 'Harassment', 'Hate Speech', 'False Information', 'Other'];
    final TextEditingController _otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.peach.withOpacity(0.5)),
              ),
              title: Text("REPORT_$targetType".toUpperCase(), style: GoogleFonts.righteous(color: AppTheme.peach)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Please select a reason:", style: GoogleFonts.spaceMono(color: Colors.white)),
                    const SizedBox(height: 10),
                    ...reasons.map((reason) => RadioListTile<String>(
                          title: Text(reason, style: GoogleFonts.spaceMono(color: Colors.white70)),
                          value: reason,
                          groupValue: selectedReason,
                          activeColor: AppTheme.peach,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedReason = val);
                          },
                        )),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _otherReasonController,
                        style: GoogleFonts.spaceMono(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Specify the reason...",
                          hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    String finalReason = selectedReason;
                    if (selectedReason == 'Other') {
                      if (_otherReasonController.text.trim().isEmpty) {
                         _showFeedback("PLEASE_SPECIFY_REASON");
                         return;
                      }
                      finalReason = "Other: ${_otherReasonController.text.trim()}";
                    }

                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final success = await ApiService.reportItem(
                      reporterId: auth.user!.id,
                      targetId: targetId,
                      targetType: targetType,
                      reason: finalReason,
                    );
                    Navigator.pop(context);
                    if (success) {
                      _showFeedback("REPORT_SUBMITTED");
                    } else {
                      _showFeedback("REPORT_FAILED");
                    }
                  },
                  child: Text("SUBMIT", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditDialog(String postId, String currentContent) {
    final _editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.peach.withOpacity(0.5)),
        ),
        title: Text("EDIT_TRANSMISSION", style: GoogleFonts.righteous(color: AppTheme.peach)),
        content: TextField(
          controller: _editController,
          maxLines: null,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: "UPDATE_DATA...",
            hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.peach,
               foregroundColor: AppTheme.darkPurple,
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
        backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.coral.withOpacity(0.5)),
        ),
        title: Text("DELETE_CONFIRMATION", style: GoogleFonts.righteous(color: AppTheme.coral)),
        content: Text("ERASE_THIS_TRANSMISSION_PERMANENTLY?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("NO", style: GoogleFonts.spaceMono(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral, foregroundColor: Colors.white),
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
        content: Text(message, style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.peach,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showToxicityAlert(String detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.coral, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.coral),
            const SizedBox(width: 10),
            Text("CONTENT_BLOCKED", style: GoogleFonts.righteous(color: AppTheme.coral)),
          ],
        ),
        content: Text(
          detail,
          style: GoogleFonts.spaceMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("UNDERSTOOD", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppTheme.darkPurple.withOpacity(0.5)),
          ),
        ),
        title: Hero(
          tag: 'logo',
          child: Text(
            'TruthNet',
            style: GoogleFonts.righteous(
              color: AppTheme.peach,
              fontSize: 32,
              letterSpacing: -1,
              shadows: [Shadow(color: AppTheme.peach.withOpacity(0.5), blurRadius: 10)],
            ),
          ),
        ),
        actions: [
          if (role != UserRole.guest)
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: AppTheme.peach),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.coral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.peach),
            onPressed: () => _fetchFeed(),
          ),
          IconButton(
            icon: Icon(role == UserRole.guest ? Icons.login_rounded : Icons.logout_rounded, color: AppTheme.coral),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading ? _buildShimmerFeed() : _buildFeed(),
      floatingActionButton: (role == UserRole.member || role == UserRole.admin)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/post');
                  if (result == true) _fetchFeed();
                },
                child: const Icon(Icons.add_rounded, color: AppTheme.darkPurple),
                backgroundColor: AppTheme.peach,
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
        return _isLoading ? _buildShimmerFeed() : _buildFeed();
      case 1:
        return _buildSearchScreen();
      case 2:
        return (role != UserRole.guest) ? _buildMessagesScreen() : Center(child: Text('LOGIN_REQUIRED_FOR_COMMS', style: GoogleFonts.spaceMono(color: AppTheme.coral)));
      case 3:
        if (role == UserRole.guest) return Center(child: Text('LOGIN_REQUIRED', style: GoogleFonts.spaceMono(color: AppTheme.coral)));
        // Note: For UserRole.admin or UserRole.moderator, their profile index might be shifted
        // CustomFloatingNavBar might return 3 for Profile, but for Admins index 3 is Mod and 4 is Admin? 
        // Wait, _getNavItems assigns labels. We should route by label or correct index.
        return ProfileScreen(key: profileKey);
      default:
        return _isLoading ? _buildShimmerFeed() : _buildFeed();
    }
  }

  Widget _buildMessagesScreen() {
    return MessageScreen();
  }

  String _searchQuery = "";
  List<dynamic> _userSearchResults = [];
  List<dynamic> _postSearchResults = [];
  bool _isSearching = false;
  int _searchTab = 0; // 0 for Users, 1 for Posts

  Widget _buildSearchScreen() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id ?? "";

    return SafeArea(
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
            // Options to view profile or message
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
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120), // Extra bottom padding for nav bar
      itemCount: _postSearchResults.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_postSearchResults[index], auth, index);
      },
    );
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
            color: AppTheme.mediumPurple.withOpacity(0.5),
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
        return _buildPostCard(_posts[index], auth, index);
      },
    );
  }

  Widget _buildPostCard(dynamic post, AuthProvider auth, int index) {
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
            color: AppTheme.mediumPurple.withOpacity(0.85), // Increased opacity to maintain look without blur
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.peach.withOpacity(0.1)),
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
                          border: Border.all(color: AppTheme.peach, width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.darkPurple,
                          child: Text(author[0].toUpperCase(), style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: authorId)));
                              },
                              child: Text("@$author", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            ),
                            if (location != null)
                              Text("📍 $location", style: GoogleFonts.spaceMono(color: AppTheme.peach.withOpacity(0.8), fontSize: 9)),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white30),
                          color: AppTheme.mediumPurple,
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
                              child: Text("ERASE_NODE", style: GoogleFonts.spaceMono(color: AppTheme.coral)),
                            ),
                          ],
                        )
                      else if (auth.user != null)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white30),
                          color: AppTheme.mediumPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.white10)),
                          onSelected: (value) {
                            if (value == 'report') _showReportDialog(postId, 'Post');
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'report',
                              child: Text("REPORT_TRANSMISSION", style: GoogleFonts.spaceMono(color: AppTheme.coral)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _buildRichText(content, fontSize: 13),
                  ),
                  if (post['mediaUrls'] != null && (post['mediaUrls'] as List).isNotEmpty)
                    _PostCarousel(urls: post['mediaUrls'] as List, isVideo: post['isVideo'] == true)
                  else if (mediaUrl != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkPurple.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: post['isVideo'] == true
                          ? VideoPlayerWidget(
                              videoUrl: "${ApiService.baseUrl.replaceFirst('/api', '')}$mediaUrl",
                            )
                          : Image.network(
                              "${ApiService.baseUrl.replaceFirst('/api', '')}$mediaUrl",
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 200,
                                  child: Icon(Icons.broken_image, color: Colors.white10),
                                );
                              },
                            ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                        '$likeCount', 
                        isLiked ? AppTheme.coral : Colors.white30, 
                        () => _handleLike(postId)
                      ),
                      _buildActionButton(Icons.comment_rounded, '$commentCount', AppTheme.peach, () => _showCommentSheet(postId)),
                      _buildActionButton(Icons.share_rounded, '$shareCount', Colors.white30, () => _handleShare(postId, content, author)),
                      _buildActionButton(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                        '', 
                        isSaved ? AppTheme.peach : Colors.white30, 
                        () => _handleSave(postId)
                      ),
                      _buildActionButton(
                        Icons.verified_user_rounded,
                        'VERIFY',
                        AppTheme.peach,
                        () => _handleVerify(post)
                      ),
                    ],
                  ),
                ],
              ),
        ).animate().fade(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1); // Staggered Animation
  }

  Future<void> _handleVerify(dynamic post) async {
    final postId = post['id'];
    final content = post['content'] ?? "";
    final mediaUrl = post['mediaUrl'];
    final isVideo = post['isVideo'] ?? false;

    // 1. Check if we already have the data in the post object (from feed)
    if (post['truthScore'] != null) {
      _showVerificationResult({
        'verdict': post['truthVerdict'],
        'truth_score': post['truthScore'],
        'explanation': post['truthExplanation'],
        'sources': post['truthSources']
      });
      return;
    }

    if (content.trim().isEmpty && mediaUrl == null) {
      _showFeedback("NO_CONTENT_TO_VERIFY");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.peach))
    );

    // If text is empty, send a placeholder or descriptive text to avoid backend rejection
    final textToSend = content.trim().isEmpty ? "[IMAGE_ONLY_POST]" : content;

    final result = await ApiService.verifyClaim(
        textToSend, 
        imageUrl: mediaUrl, 
        isVideo: isVideo,
        postId: postId
    );
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result['success'] == true) {
      _showVerificationResult(result);
    } else {
      _showFeedback(result['message'] ?? "VERIFICATION_FAILED");
    }
  }

  void _showVerificationResult(Map<String, dynamic> data) {
    final verdict = data['verdict'] ?? 'Unverified';
    final isClaim = data['is_claim'] ?? true;
    final score = (data['truth_score'] ?? 0.5) * 100;
    final explanation = data['explanation'] ?? 'No explanation provided.';
    final sources = data['sources'] as List? ?? [];

    Color verdictColor;
    IconData verdictIcon;
    
    switch (verdict.toString().toLowerCase()) {
      case 'verified':
        verdictColor = Colors.green;
        verdictIcon = Icons.check_circle_rounded;
        break;
      case 'false':
        verdictColor = Colors.redAccent;
        verdictIcon = Icons.cancel_rounded;
        break;
      case 'partially true':
        verdictColor = Colors.orange;
        verdictIcon = Icons.warning_rounded;
        break;
      case 'not a claim':
        verdictColor = Colors.white54;
        verdictIcon = Icons.info_outline_rounded;
        break;
      default:
        verdictColor = Colors.blue;
        verdictIcon = Icons.help_rounded;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: verdictColor.withOpacity(0.5), width: 2),
        ),
        title: Row(
          children: [
            Icon(verdictIcon, color: verdictColor),
            const SizedBox(width: 10),
            Text(verdict.toUpperCase(), style: GoogleFonts.righteous(color: verdictColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isClaim && verdict != 'Not a Claim')
                Text(
                  "Truth Score: ${score.toStringAsFixed(0)}%",
                  style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              if (verdict == 'Not a Claim')
                Text(
                  "Non-Factual Content",
                  style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              const SizedBox(height: 15),
              Text(
                explanation,
                style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12),
              ),
              if (sources.isNotEmpty && verdict != 'Not a Claim') ...[
                const SizedBox(height: 15),
                Text("Reliability signals:", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 10, fontWeight: FontWeight.bold)),
                ...sources.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("• $s", style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 10)),
                )).toList(),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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

class _PostCarousel extends StatefulWidget {
  final List urls;
  final bool isVideo;
  const _PostCarousel({required this.urls, this.isVideo = false});

  @override
  _PostCarouselState createState() => _PostCarouselState();
}

class _PostCarouselState extends State<_PostCarousel> {
  int _currentPage = 0;
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    Widget carouselContent = ScrollConfiguration(
      behavior: _CarouselScrollBehavior(),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (idx) => setState(() => _currentPage = idx),
        itemBuilder: (context, idx) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppTheme.darkPurple.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: widget.isVideo 
                ? VideoPlayerWidget(videoUrl: "${ApiService.baseUrl.replaceFirst('/api', '')}${widget.urls[idx]}")
                : Image.network(
                    "${ApiService.baseUrl.replaceFirst('/api', '')}${widget.urls[idx]}",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white10)),
                  ),
            ),
          );
        },
      ),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 5),
          child: widget.isVideo 
            ? AspectRatio(aspectRatio: 16 / 9, child: carouselContent)
            : SizedBox(height: 300, child: carouselContent),
        ),
        if (widget.urls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.urls.length, (idx) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == idx ? AppTheme.peach : Colors.white10,
              ),
            )),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CarouselScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
