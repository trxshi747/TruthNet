import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/screens/chat_screen.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      final convos = await ApiService.getConversations(auth.user!.id);
      if (mounted) {
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("MESSAGES", style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 24)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.peach),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchConversations();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
                : _conversations.isEmpty
                    ? Center(child: Text("NO_COMMUNICATIONS_DETECTED", style: GoogleFonts.spaceMono(color: Colors.white24)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120), // Avoid nav bar overlap
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final convo = _conversations[index];
                          final String username = convo['username'] ?? "UNKNOWN";
                          final String lastMsg = convo['lastMessage'] ?? "";
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.mediumPurple.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.peach,
                                child: Text(username[0].toUpperCase(), style: const TextStyle(color: AppTheme.darkPurple)),
                              ),
                              title: Text("@$username", style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                lastMsg, 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis, 
                                style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12)
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => ChatScreen(
                                    otherUserId: convo['id'], 
                                    otherUsername: username
                                  ))
                                ).then((_) => _fetchConversations());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}