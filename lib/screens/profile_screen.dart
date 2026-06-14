import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/screens/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:model2/widgets/video_player_widget.dart';

import 'package:model2/core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  const ProfileScreen({Key? key, this.targetUserId}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _userPosts = [];
  List<dynamic> _archivePosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _currentTab = 0; // 0 for Posts, 1 for Archive

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userIdToFetch = widget.targetUserId ?? auth.user?.id;
    final isOwner = widget.targetUserId == null || widget.targetUserId == auth.user?.id;

    if (userIdToFetch != null) {
      final profile = await ApiService.getProfile(userIdToFetch, auth.user?.id ?? '');
      final posts = await ApiService.getUserPosts(userIdToFetch);
      final archive = isOwner ? await ApiService.getArchivePosts(userIdToFetch) : [];

      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _userPosts = posts;
        _archivePosts = archive;
        _isFollowing = profile['isFollowing'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermanentDelete(String postId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mediumPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.coral.withOpacity(0.5)),
        ),
        title: Text("CRITICAL_ERASURE", style: GoogleFonts.righteous(color: AppTheme.coral)),
        content: Text("ERASE_TRANSMISSION_PERMANENTLY_FROM_CORE?", style: GoogleFonts.spaceMono(color: Colors.white70)),
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
      final success = await ApiService.deletePostPermanent(postId, auth.user!.id);
      if (success) {
        fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("NODE_PERMANENTLY_ERASED", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: AppTheme.darkPurple)),
            backgroundColor: AppTheme.peach,
          )
        );
      }
    }
  }

  void _showEditProfile() {
    final _firstNameController = TextEditingController(text: _profileData?['firstName']);
    final _lastNameController = TextEditingController(text: _profileData?['lastName']);
    final _bioController = TextEditingController(text: _profileData?['bio'] ?? "");
    XFile? _newAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: AppTheme.mediumPurple.withOpacity(0.85),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 15),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Text("CUSTOMIZE_IDENTITY", style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 20)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) setModalState(() => _newAvatar = image);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.peach, width: 2),
                          boxShadow: [BoxShadow(color: AppTheme.peach.withOpacity(0.2), blurRadius: 15)]
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.darkPurple,
                          backgroundImage: _newAvatar != null
                            ? (kIsWeb ? NetworkImage(_newAvatar!.path) : FileImage(File(_newAvatar!.path)) as ImageProvider)
                            : (_profileData?['avatar'] != null ? NetworkImage("${ApiService.baseUrl.replaceFirst('/api', '')}${_profileData!['avatar']}") : null),
                          child: _newAvatar == null && _profileData?['avatar'] == null ? const Icon(Icons.camera_alt, color: AppTheme.peach) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _firstNameController,
                      style: GoogleFonts.spaceMono(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "FIRST_NAME",
                        labelStyle: GoogleFonts.spaceMono(color: AppTheme.peach),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _lastNameController,
                      style: GoogleFonts.spaceMono(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "LAST_NAME",
                        labelStyle: GoogleFonts.spaceMono(color: AppTheme.peach),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _bioController,
                      style: GoogleFonts.spaceMono(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "BIOGRAPHY_DATA",
                        labelStyle: GoogleFonts.spaceMono(color: AppTheme.peach),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.peach)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: AppTheme.peach.withOpacity(0.3), blurRadius: 15)],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.peach,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await ApiService.updateProfile(
                            auth.user!.id,
                            _firstNameController.text,
                            _lastNameController.text,
                            _bioController.text,
                            _newAvatar
                          );
                          auth.updateLocalProfile(_firstNameController.text, _lastNameController.text, _bioController.text);
                          Navigator.pop(context);
                          fetchProfile();
                        },
                        child: Text("SYNC_CHANGES", style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.targetUserId != null
        ? const Scaffold(body: DynamicBackground(child: Center(child: CircularProgressIndicator(color: AppTheme.peach))))
        : const Center(child: CircularProgressIndicator(color: AppTheme.peach));
    }

    final content = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader().animate().fade(delay: 100.ms).slideY(begin: 0.1),
          const SizedBox(height: 30),
          _buildStatsRow().animate().fade(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 30),
          _buildTabSwitcher().animate().fade(delay: 300.ms),
          Expanded(child: _buildContentList().animate().fade(delay: 400.ms)),
        ],
      ),
    );

    if (widget.targetUserId != null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: null,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.peach),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: DynamicBackground(child: content),
      );
    }

    return content;
  }

  Widget _buildProfileHeader() {
    String username = _profileData?['username'] ?? 'user';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = widget.targetUserId == null || widget.targetUserId == auth.user?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.peach, width: 2),
              boxShadow: [BoxShadow(color: AppTheme.peach.withOpacity(0.2), blurRadius: 20)]
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.darkPurple,
              backgroundImage: _profileData?['avatar'] != null
                ? NetworkImage("${ApiService.baseUrl.replaceFirst('/api', '')}${_profileData!['avatar']}")
                : null,
              child: _profileData?['avatar'] == null
                ? Text(username[0].toUpperCase(), style: GoogleFonts.righteous(fontSize: 30, color: AppTheme.peach))
                : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("@$username", style: GoogleFonts.righteous(fontSize: 22, color: AppTheme.peach)),
                    if (isOwner)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10)
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppTheme.peach, size: 20),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                  ],
                ),
                Text("${_profileData?['firstName'] ?? ''} ${_profileData?['lastName'] ?? ''}".trim(), style: GoogleFonts.spaceMono(color: AppTheme.coral.withOpacity(0.7), fontSize: 11)),
                const SizedBox(height: 8),
                Text(_profileData?['bio'] ?? "NO_DATA_AVAILABLE", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 12),
                if (isOwner)
                  InkWell(
                    onTap: _showEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.peach.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.peach.withOpacity(0.3)),
                      ),
                      child: Text("EDIT_IDENTITY", style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.peach, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  InkWell(
                    onTap: () async {
                      if(auth.user?.id == null || widget.targetUserId == null) return;
                      final result = await ApiService.followUser(auth.user!.id, widget.targetUserId!);
                      print("Follow/Unfollow API Result: $result"); // Debugging line
                      if (result['success'] == true) {
                        setState(() {
                          _isFollowing = !_isFollowing;
                          int currentFollowers = _profileData?['followerCount'] ?? 0;
                           _profileData?['followerCount'] = _isFollowing ? currentFollowers + 1 : currentFollowers - 1;
                        });
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Action failed: ${result['message'] ?? 'Unknown error'}", style: GoogleFonts.spaceMono(color: Colors.white)),
                            backgroundColor: AppTheme.coral,
                          )
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isFollowing ? Colors.transparent : AppTheme.peach,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.peach),
                      ),
                      child: Text(
                        _isFollowing ? "FOLLOWING" : "FOLLOW",
                        style: GoogleFonts.spaceMono(fontSize: 10, color: _isFollowing ? AppTheme.peach : AppTheme.darkPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.mediumPurple.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("TRANSMISSIONS", _profileData?['postCount']?.toString() ?? "0"),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem("FOLLOWERS", _profileData?['followerCount']?.toString() ?? "0"),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem("FOLLOWING", _profileData?['followingCount']?.toString() ?? "0"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.righteous(fontSize: 20, color: AppTheme.peach, shadows: [Shadow(color: AppTheme.peach.withOpacity(0.5), blurRadius: 10)])),
        Text(label, style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white54)),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = widget.targetUserId == null || widget.targetUserId == auth.user?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        children: [
          _buildTab("POSTS", 0),
          if (isOwner) ...[
            const SizedBox(width: 25),
            _buildTab("ARCHIVE", 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool active = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.righteous(color: active ? AppTheme.peach : Colors.white24, fontSize: 16)),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.peach,
                boxShadow: [BoxShadow(color: AppTheme.peach, blurRadius: 5)]
              )
            ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    final list = _currentTab == 0 ? _userPosts : _archivePosts;
    if (list.isEmpty) return Center(child: Text("NO_RECORDS_FOUND", style: GoogleFonts.spaceMono(color: Colors.white24)));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120), // Extra padding for nav bar
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.mediumPurple.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.peach.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("@${item['author'] ?? "SOURCE"}", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontSize: 10, fontWeight: FontWeight.bold)),
                  if (_currentTab == 1) // Only show permanent delete in Archive
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.coral, size: 20),
                      onPressed: () => _handlePermanentDelete(item['id']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(item['content'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 12),
              if (item['mediaUrl'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: item['isVideo'] == true
                      ? SizedBox(
                          height: 150,
                          child: VideoPlayerWidget(
                            videoUrl: "${ApiService.baseUrl.replaceFirst('/api', '')}${item['mediaUrl']}",
                          ),
                        )
                      : Image.network(
                          "${ApiService.baseUrl.replaceFirst('/api', '')}${item['mediaUrl']}",
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
            ],
          ),
        ).animate().fade(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }
}
