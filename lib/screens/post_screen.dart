import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isPublic = true;
  bool _isLoading = false;
  XFile? _mediaFile;
  bool _isVideo = false;
  String? _locationString;
  String? _placeName;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleImageAction() async {
    _showPickerOptions(
      title: 'SELECT_IMAGE_SOURCE',
      onGallery: () async {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) setState(() { _mediaFile = image; _isVideo = false; });
      },
      onCamera: () async {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        if (image != null) setState(() { _mediaFile = image; _isVideo = false; });
      },
    );
  }

  Future<void> _handleVideoAction() async {
    _showPickerOptions(
      title: 'SELECT_VIDEO_SOURCE',
      onGallery: () async {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) setState(() { _mediaFile = video; _isVideo = true; });
      },
      onCamera: () async {
        final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
        if (video != null) setState(() { _mediaFile = video; _isVideo = true; });
      },
    );
  }

  void _showPickerOptions({required String title, required Function onGallery, required Function onCamera}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF312C51),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: GoogleFonts.spaceMono(color: const Color(0xFFF1AA9B), fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 10),
          ],
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
        
        // REVERSE GEOCODING: Get Place Name
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
    if (_contentController.text.trim().isEmpty && _mediaFile == null) return;
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
        mediaFile: _mediaFile,
        isVideo: _isVideo,
        location: locData,
      );
      
      if (result['id'] != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('POST_BROADCAST_SUCCESSFUL', style: GoogleFonts.spaceMono()),
            backgroundColor: const Color(0xFFF0C38E),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('NEW_POST', style: GoogleFonts.righteous(fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF0C38E)))
              : TextButton(
                  onPressed: _handlePost,
                  child: Text('POST', style: GoogleFonts.righteous(color: const Color(0xFFF0C38E), fontSize: 18)),
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
                _buildHeader(authProvider),
                const SizedBox(height: 20),
                if (_mediaFile != null) _buildMediaPreview(),
                Expanded(child: _buildEditor()),
                const Divider(height: 40, color: Colors.white10),
                _buildActionToolbar(),
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
        CircleAvatar(
          backgroundColor: const Color(0xFFF1AA9B),
          child: Text(auth.user?.name[0] ?? 'U', style: const TextStyle(color: Color(0xFF312C51))),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.user?.name ?? 'USER', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
            if (_locationString != null)
              Text(
                "📍 ${_placeName != null ? '$_placeName ' : ''}($_locationString)", 
                style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFFF1AA9B))
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF0C38E), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _isVideo 
                ? Container(color: Colors.black, child: const Icon(Icons.play_circle_fill, size: 50, color: Colors.white54))
                : (kIsWeb 
                    ? Image.network(_mediaFile!.path, fit: BoxFit.cover) 
                    : Image.file(File(_mediaFile!.path), fit: BoxFit.cover)),
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => setState(() => _mediaFile = null),
          ),
        )
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF48426D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        style: GoogleFonts.spaceMono(),
        decoration: InputDecoration(
          hintText: "INPUT_DATA_HERE...",
          hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
          border: InputBorder.none,
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
        Switch(
          value: _isPublic,
          activeColor: const Color(0xFFF0C38E),
          onChanged: (val) => setState(() => _isPublic = val),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF48426D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(icon: Icon(icon, color: const Color(0xFFF1AA9B)), onPressed: onTap),
    );
  }
}
