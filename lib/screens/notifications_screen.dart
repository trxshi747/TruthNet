import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/notification_provider.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/screens/profile_screen.dart';
import 'package:model2/screens/single_post_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("NOTIFICATIONS", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.peach),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            tooltip: 'Mark all as read',
          )
        ],
      ),
      body: DynamicBackground(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.notifications.isEmpty) {
              return Center(
                child: Text(
                  "NO_NEW_NOTIFICATIONS",
                  style: GoogleFonts.spaceMono(color: Colors.white54),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                final isRead = notif['isRead'] ?? false;
                
                IconData icon;
                Color iconColor;
                
                switch (notif['type']) {
                  case 'like_post':
                  case 'like_comment':
                    icon = Icons.favorite_rounded;
                    iconColor = AppTheme.coral;
                    break;
                  case 'comment':
                  case 'reply':
                    icon = Icons.chat_bubble_rounded;
                    iconColor = AppTheme.mediumPurple;
                    break;
                  case 'follow':
                    icon = Icons.person_add_rounded;
                    iconColor = AppTheme.peach;
                    break;
                  default:
                    icon = Icons.notifications_rounded;
                    iconColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      provider.markAsRead(notif['id']);
                    }
                    if (notif['postId'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SinglePostScreen(postId: notif['postId']),
                        ),
                      );
                    } else if (notif['actorId'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(targetUserId: notif['actorId']),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.black26 : AppTheme.darkPurple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead ? Colors.white10 : AppTheme.peach.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: "@${notif['actorUsername']} ",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.peach),
                                    ),
                                    TextSpan(text: notif['text']),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notif['createdAt']),
                                style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.peach,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
