import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;

  const ChatScreen({Key? key, required this.otherUserId, required this.otherUsername}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Simulate Real-time with 3-second polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    if (!isBackground) {
      setState(() => _isLoading = true);
    }
    
    final messages = await ApiService.getChatHistory(auth.user!.id, widget.otherUserId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    _messageController.clear();
    
    // Optimistic insert
    setState(() {
      _messages.add({
        'content': text,
        'senderId': auth.user!.id,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
    
    // Scroll to bottom immediately
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    await ApiService.sendMessage(auth.user!.id, widget.otherUserId, text);
    _fetchMessages(isBackground: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final myId = auth.user?.id ?? "";

    return Scaffold(
      backgroundColor: AppTheme.darkPurple,
      appBar: AppBar(
        backgroundColor: AppTheme.mediumPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.peach),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("@${widget.otherUsername}", style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
                : _messages.isEmpty
                    ? Center(child: Text("NO_HISTORY_FOUND", style: GoogleFonts.spaceMono(color: Colors.white24)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isMe = msg['senderId'] == myId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.peach.withOpacity(0.9) : AppTheme.mediumPurple,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                msg['content'] ?? "",
                                style: GoogleFonts.spaceMono(
                                  color: isMe ? AppTheme.darkPurple : Colors.white,
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: AppTheme.mediumPurple,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.spaceMono(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "TRANSMIT...",
                        hintStyle: GoogleFonts.spaceMono(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.peach,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.darkPurple),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}