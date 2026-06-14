import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:model2/core/theme/app_theme.dart';

// Custom controller to highlight @tags in peach
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
          style: style?.copyWith(
            color: AppTheme.peach, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: AppTheme.peach.withOpacity(0.5), blurRadius: 5)],
          ),
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

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TaggingTextEditingController _contentController = TaggingTextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isPublic = true;
  bool _isLoading = false;
  List<XFile> _mediaFiles = [];
  bool _isVideo = false;
  String? _locationString;
  String? _placeName;
  List<dynamic> _userSearchResults = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleImageAction() async {
    _showPickerOptions(
      title: 'SELECT_IMAGE_SOURCE',
      onGallery: () async {
        final List<XFile>? images = await _picker.pickMultiImage();
        if (images != null && images.isNotEmpty) {
          setState(() {
            _mediaFiles.addAll(images);
            _isVideo = false;
          });
        }
      },
      onCamera: () async {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          setState(() {
            _mediaFiles.add(image);
            _isVideo = false;
          });
        }
      },
    );
  }

  Future<void> _handleVideoAction() async {
    _showPickerOptions(
      title: 'SELECT_VIDEO_SOURCE',
      onGallery: () async {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          if (video.name.toLowerCase().endsWith('.mp4')) {
            setState(() {
              _mediaFiles = [video];
              _isVideo = true;
            });
          } else {
            _showFeedback("PROTOCOL_ERROR: ONLY_MP4_VIDEOS_ACCEPTED");
          }
        }
      },
      onCamera: () async {
        final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
        if (video != null) {
          if (video.name.toLowerCase().endsWith('.mp4')) {
            setState(() {
              _mediaFiles = [video];
              _isVideo = true;
            });
          } else {
            _showFeedback("PROTOCOL_ERROR: ONLY_MP4_VIDEOS_ACCEPTED");
          }
        }
      },
    );
  }

  void _showPickerOptions({required String title, required Function onGallery, required Function onCamera}) {   
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: AppTheme.mediumPurple.withOpacity(0.85),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 15),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(title, style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.collections_rounded, color: Colors.white),
                    title: Text('FROM_GALLERY', style: GoogleFonts.spaceMono(color: Colors.white)),
                    onTap: () { Navigator.pop(context); onGallery(); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    title: Text('USE_CAMERA', style: GoogleFonts.spaceMono(color: Colors.white)),
                    onTap: () { Navigator.pop(context); onCamera(); },
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

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();

        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);   
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              _placeName = "${place.locality}, ${place.country}";
            });
          }
        } catch (e) {
          debugPrint("Geocoding Error: $e");
        }

        setState(() {
          _locationString = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty && _mediaFiles.isEmpty) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      final String locData = _placeName != null
          ? "$_placeName ($_locationString)"
          : (_locationString ?? "");

      final result = await ApiService.createPost(
        userId: userId,
        content: _contentController.text.trim(),
        isPublic: _isPublic,
        mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
        isVideo: _isVideo,
        location: locData,
      );

      if (result['id'] != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('POST_BROADCAST_SUCCESSFUL', style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.peach,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result['message'] == 'CONTENT_TOO_TOXIC') {
          _showToxicityAlert(result['detail'] ?? "Your content is too toxic to be published.");
      } else if (result['message'] == 'CONTENT_UNVERIFIED' || result['message'] == 'CONTENT_NONSENSE') {
          _showRejectionAlert(result);
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'UPLOAD_FAILED', style: GoogleFonts.spaceMono(color: Colors.white)),
              backgroundColor: AppTheme.coral,
            ),
          );
      }
    }
    setState(() => _isLoading = false);
  }

  void _showRejectionAlert(Map<String, dynamic> data) {
    final verdict = data['verdict'] ?? 'Unverified';
    final score = ((data['truth_score'] ?? 0.0) * 100).toDouble();
    final explanation = data['detail'] ?? 'No explanation provided.';

    Color verdictColor = Colors.orange;
    IconData verdictIcon = Icons.fact_check_rounded;
    
    if (data['message'] == 'CONTENT_NONSENSE') {
      verdictColor = Colors.white54;
      verdictIcon = Icons.help_outline_rounded;
    } else if (verdict.toString().toLowerCase() == 'false') {
      verdictColor = Colors.redAccent;
      verdictIcon = Icons.cancel_rounded;
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
            Text(verdict.toString().toUpperCase(), style: GoogleFonts.righteous(color: verdictColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['message'] != 'CONTENT_NONSENSE')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "Truth Score: ${score.toStringAsFixed(0)}%",
                    style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              Text(
                explanation,
                style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: verdictColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_flipped, size: 16, color: verdictColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "THIS_POST_WILL_NOT_BE_PUBLISHED",
                        style: GoogleFonts.spaceMono(color: verdictColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('NEW_TRANSMISSION', style: GoogleFonts.righteous(fontSize: 20, color: AppTheme.peach)),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppTheme.darkPurple.withOpacity(0.5)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.peach))
              : Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.peach.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.peach.withOpacity(0.5))
                  ),
                  child: TextButton(
                    onPressed: _handlePost,
                    child: Text('TRANSMIT', style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
          ),
        ],
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(authProvider).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
                if (_mediaFiles.isNotEmpty) _buildMediaPreview().animate().fade().scale(begin: const Offset(0.9, 0.9)),
                Expanded(
                  child: Stack(
                    children: [
                      _buildEditor().animate().fade(delay: 200.ms).slideY(begin: 0.2),
                      if (_userSearchResults.isNotEmpty) _buildTaggingOverlay(),
                    ],
                  ),
                ),
                const Divider(height: 40, color: Colors.white10),
                _buildActionToolbar().animate().fade(delay: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.peach, width: 1.5),
            boxShadow: [BoxShadow(color: AppTheme.peach.withOpacity(0.3), blurRadius: 10)]
          ),
          child: CircleAvatar(
            backgroundColor: AppTheme.darkPurple,
            child: Text(auth.user?.username[0].toUpperCase() ?? 'U', style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("@${auth.user?.username ?? 'USER'}", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white)),
            if (_locationString != null)
              Text(
                "📍 ${_placeName != null ? '$_placeName ' : ''}($_locationString)",
                style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.peach.withOpacity(0.8))
              ),
          ],
        ),
      ],
    );
  }
  Widget _buildMediaPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        itemBuilder: (context, index) {
          final file = _mediaFiles[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.peach.withOpacity(0.5), width: 1),
              boxShadow: [BoxShadow(color: AppTheme.peach.withOpacity(0.1), blurRadius: 20)]
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _isVideo
                      ? Container(
                          color: Colors.black, 
                          child: const Icon(Icons.play_circle_fill, size: 50, color: AppTheme.peach)
                        )
                      : (kIsWeb
                          ? Image.network(file.path, fit: BoxFit.cover)
                          : Image.file(File(file.path), fit: BoxFit.cover)),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => _mediaFiles.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: AppTheme.coral),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditor() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.mediumPurple.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _contentController,
            onChanged: (text) async {
              final int atIndex = text.lastIndexOf('@');
              if (atIndex != -1) {
                final String query = text.substring(atIndex + 1);
                if (!query.contains(' ')) {
                  final results = await ApiService.searchUsers(query);
                  setState(() {
                    _userSearchResults = results;
                  });
                  return;
                }
              }
              if (_userSearchResults.isNotEmpty) {
                setState(() {
                  _userSearchResults = [];
                });
              }
            },
            maxLines: null,
            style: GoogleFonts.spaceMono(color: Colors.white),
            decoration: InputDecoration(
              hintText: "INPUT_DATA_HERE...",
              hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaggingOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: AppTheme.mediumPurple.withOpacity(0.85),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.peach.withOpacity(0.3)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
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
                    final text = _contentController.text;
                    final atIndex = text.lastIndexOf('@');
                    final newText = text.substring(0, atIndex) + "@${user['name']} ";
                    _contentController.text = newText;
                    _contentController.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
                    setState(() => _userSearchResults = []);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionToolbar() {
    return Row(
      children: [
        _buildIconButton(Icons.image_outlined, _handleImageAction),
        _buildIconButton(Icons.videocam_outlined, _handleVideoAction),
        _buildIconButton(Icons.location_on_outlined, _getLocation),
        const Spacer(),
        Text("PUBLIC", style: GoogleFonts.spaceMono(color: _isPublic ? AppTheme.peach : Colors.white54, fontSize: 10)),
        Switch(
          value: _isPublic,
          activeColor: AppTheme.peach,
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: Colors.white10,
          onChanged: (val) => setState(() => _isPublic = val),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10)
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.peach), 
        onPressed: onTap,
        splashColor: AppTheme.peach.withOpacity(0.2),
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.peach,
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  }