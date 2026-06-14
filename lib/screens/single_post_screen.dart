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
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: _buildActionButton(
              Icons.verified_user_rounded,
              'VERIFY',
              AppTheme.peach,
              () => _handleVerify(),
            ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (_post == null) return;
    
    // Check cache
    if (_post!['truthScore'] != null) {
      _showVerificationResult({
        'verdict': _post!['truthVerdict'],
        'truth_score': _post!['truthScore'],
        'explanation': _post!['truthExplanation'],
        'sources': _post!['truthSources']
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.peach))
    );

    final content = _post!['content'] ?? "";
    final mediaUrl = _post!['mediaUrl'];
    final isVideo = _post!['isVideo'] ?? false;
    final textToSend = content.trim().isEmpty ? "[IMAGE_ONLY_POST]" : content;

    final result = await ApiService.verifyClaim(
        textToSend, 
        imageUrl: mediaUrl, 
        isVideo: isVideo,
        postId: widget.postId
    );
    
    if (!mounted) return;
    Navigator.pop(context);

    if (result['success'] == true) {
      _showVerificationResult(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "VERIFICATION_FAILED"), backgroundColor: AppTheme.coral),
      );
    }
  }

  void _showVerificationResult(Map<String, dynamic> data) {
    final verdict = data['verdict'] ?? 'Unverified';
    final score = (data['truth_score'] ?? 0.5) * 100;
    final explanation = data['explanation'] ?? 'No explanation provided.';
    final sources = data['sources'] as List? ?? [];

    Color verdictColor;
    switch (verdict.toString().toLowerCase()) {
      case 'verified': verdictColor = Colors.green; break;
      case 'false': verdictColor = Colors.redAccent; break;
      case 'partially true': verdictColor = Colors.orange; break;
      default: verdictColor = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: verdictColor.withOpacity(0.5), width: 2)),
        title: Text(verdict.toUpperCase(), style: GoogleFonts.righteous(color: verdictColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Truth Score: ${score.toStringAsFixed(0)}%", style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(explanation, style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CLOSE", style: GoogleFonts.spaceMono(color: AppTheme.peach))),
        ],
      ),
    );
  }
}
