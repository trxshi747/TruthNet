import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/widgets/video_player_widget.dart';
import 'package:model2/screens/profile_screen.dart';

class SinglePostScreen extends StatefulWidget {
  final String postId;

  const SinglePostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _SinglePostScreenState createState() => _SinglePostScreenState();
}

class _SinglePostScreenState extends State<SinglePostScreen> {
  Map<String, dynamic>? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      final post = await ApiService.getPost(widget.postId, auth.user!.id);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("TRANSMISSION", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.peach),
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
              : _post == null
                  ? Center(child: Text("POST_NOT_FOUND", style: GoogleFonts.spaceMono(color: AppTheme.coral)))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildPostContent(),
                        const SizedBox(height: 20),
                        // Here you could add comments list if needed, similar to home_screen
                        // For now, it focuses on viewing the post.
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.peach.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (_post?['authorId'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: _post!['authorId'])));
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.darkPurple,
                  child: Text(
                    (_post?['author'] ?? "A")[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.peach),
                  ),
                ),
                const SizedBox(width: 10),
                Text("@${_post?['author'] ?? "UNKNOWN"}", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(_post?['content'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 15),
          if (_post?['mediaUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _post?['isVideo'] == true
                  ? SizedBox(
                      height: 200,
                      child: VideoPlayerWidget(videoUrl: "${ApiService.baseUrl.replaceFirst('/api', '')}${_post!['mediaUrl']}"),
                    )
                  : Image.network(
                      "${ApiService.baseUrl.replaceFirst('/api', '')}${_post!['mediaUrl']}",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
        ],
      ),
    );
  }
}
