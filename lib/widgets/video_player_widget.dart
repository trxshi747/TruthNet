import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      debugPrint("INIT_VIDEO_STREAM: ${widget.videoUrl}");
      
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      await _videoPlayerController.initialize();
      
      final videoRatio = _videoPlayerController.value.aspectRatio;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        // Use the actual aspect ratio to prevent black bars
        aspectRatio: videoRatio, 
        
        // Maximizing Controls
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        playbackSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        
        // Themed Controls
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.peach,
          handleColor: AppTheme.peach,
          backgroundColor: Colors.white10,
          bufferedColor: Colors.white24,
        ),
        
        autoInitialize: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: AppTheme.peach)),
        ),
        
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 40),
                const SizedBox(height: 10),
                Text(
                  "STREAM_DECODE_ERROR",
                  style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("VIDEO_INIT_ERROR: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: AppTheme.coral, size: 40),
              const SizedBox(height: 12),
              Text(
                "LINK_FAILURE: $_errorMessage",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.peach, size: 18),
                label: Text("RETRY_SYNC", style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Theme(
          data: ThemeData.dark().copyWith(
            iconTheme: const IconThemeData(size: 24, color: Colors.white),
          ),
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return Container(
      height: 200,
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(color: AppTheme.peach)),
    );
  }
}
