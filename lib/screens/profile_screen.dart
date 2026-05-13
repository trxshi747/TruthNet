import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/screens/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _userPosts = [];
  List<dynamic> _archivePosts = [];
  bool _isLoading = true;
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
    if (auth.user != null) {
      final profile = await ApiService.getProfile(auth.user!.id);
      final posts = await ApiService.getUserPosts(auth.user!.id);
      final archive = await ApiService.getArchivePosts(auth.user!.id);

      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _userPosts = posts;
        _archivePosts = archive;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermanentDelete(String postId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF312C51),
        title: Text("CRITICAL_ERASURE", style: GoogleFonts.righteous(color: Colors.redAccent)),
        content: Text("ERASE_TRANSMISSION_PERMANENTLY_FROM_CORE?", style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("NO", style: GoogleFonts.spaceMono(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("YES_ERASE", style: GoogleFonts.spaceMono(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deletePostPermanent(postId, auth.user!.id);
      if (success) {
        fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NODE_PERMANENTLY_ERASED")));
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
      backgroundColor: const Color(0xFF312C51),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("CUSTOMIZE_IDENTITY", style: GoogleFonts.righteous(color: const Color(0xFFF0C38E), fontSize: 20)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setModalState(() => _newAvatar = image);
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF48426D),
                  backgroundImage: _newAvatar != null 
                    ? (kIsWeb ? NetworkImage(_newAvatar!.path) : FileImage(File(_newAvatar!.path)) as ImageProvider)
                    : (_profileData?['avatar'] != null ? NetworkImage("${ApiService.baseUrl.replaceFirst('/api', '')}${_profileData?['avatar']}") : null),
                  child: _newAvatar == null && _profileData?['avatar'] == null ? const Icon(Icons.camera_alt, color: Colors.white54) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _firstNameController,
                style: GoogleFonts.spaceMono(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "FIRST_NAME",
                  labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _lastNameController,
                style: GoogleFonts.spaceMono(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "LAST_NAME",
                  labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _bioController,
                style: GoogleFonts.spaceMono(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "BIOGRAPHY_DATA",
                  labelStyle: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C38E),
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
                child: Text("SYNC_CHANGES", style: GoogleFonts.spaceMono(color: const Color(0xFF312C51), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: DynamicBackground(child: Center(child: CircularProgressIndicator(color: Color(0xFFF0C38E)))));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildTabSwitcher(),
              Expanded(child: _buildContentList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    String name = "${_profileData?['firstName'] ?? ''} ${_profileData?['lastName'] ?? ''}".trim();
    if (name.isEmpty) name = "UNKNOWN";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0C38E), width: 2),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF48426D),
              backgroundImage: _profileData?['avatar'] != null 
                ? NetworkImage("${ApiService.baseUrl.replaceFirst('/api', '')}${_profileData?['avatar']}") 
                : null,
              child: _profileData?['avatar'] == null 
                ? Text(name[0].toUpperCase(), style: GoogleFonts.righteous(fontSize: 30, color: Colors.white))
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
                    Text(name, style: GoogleFonts.righteous(fontSize: 22, color: const Color(0xFFF0C38E))),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text("@${_profileData?['username'] ?? 'user'}", style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontSize: 12)),
                const SizedBox(height: 8),
                Text(_profileData?['bio'] ?? "NO_DATA_AVAILABLE", style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showEditProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text("EDIT_IDENTITY", style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white70)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("TRANSMISSIONS", _profileData?['postCount']?.toString() ?? "0"),
        _buildStatItem("FOLLOWERS", _profileData?['followerCount']?.toString() ?? "0"),
        _buildStatItem("FOLLOWING", _profileData?['followingCount']?.toString() ?? "0"),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.righteous(fontSize: 18, color: Colors.white)),
        Text(label, style: GoogleFonts.spaceMono(fontSize: 9, color: const Color(0xFFF1AA9B))),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        children: [
          _buildTab("POSTS", 0),
          const SizedBox(width: 15),
          _buildTab("ARCHIVE", 1),
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
          Text(label, style: GoogleFonts.righteous(color: active ? const Color(0xFFF0C38E) : Colors.white24, fontSize: 14)),
          if (active) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 40, color: const Color(0xFFF0C38E)),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    final list = _currentTab == 0 ? _userPosts : _archivePosts;
    if (list.isEmpty) return Center(child: Text("NO_RECORDS_FOUND", style: GoogleFonts.spaceMono(color: Colors.white10)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF48426D).withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['author'] ?? "SOURCE", style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontSize: 10, fontWeight: FontWeight.bold)),
                  if (_currentTab == 1) // Only show permanent delete in Archive
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                      onPressed: () => _handlePermanentDelete(item['id']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(item['content'] ?? "", style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 8),
              if (item['id'] != null)
                Text("ID: ${item['id'].toString().substring(0,8)}...", style: GoogleFonts.spaceMono(color: Colors.white10, fontSize: 8)),
            ],
          ),
        );
      },
    );
  }
}
